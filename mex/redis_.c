// compile hint

/*
 * MATLAB
 * mex -lhiredis -I/usr/include/hiredis/ CFLAGS='-fPIC -std=c99 -O4 -pedantic -g' redis_.c
 *
 * GNU OCTAVE
 * mkoctfile -Wall -Wextra -v -I/usr/include/hiredis --mex redis_.c -lhiredis -std=c99
 */

// C specific includes
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

// get it from here
// https://github.com/redis/hiredis/
#include <hiredis.h>

// Matlab/GNU Octave specific includes
#include <mex.h>

// define column major order index
#define CMOindex(c, r, rows) ( (c - 1) * rows + (r - 1) + 1 )

//#define DEBUG

// declarate some stuff
char* redisReturn;
char *hostname, *command, *password, *key, *value;
int port, database;
char redisChar[19]; // afaik long enough for long long int
mxArray *cell_array_ptr;

// matlab/octave mex function
void mexFunction (int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
  // --- input checks
  // currently we need at least more than one input and one ouput!!
  // improve me!!
  if(nrhs < 1 && nlhs != 1) {
    mexErrMsgIdAndTxt( "MATLAB:redis_:invalidNumInputs",
                      "One or more inputs are required.");
  }

  // default stuff
  hostname  = "127.0.0.1";
  port      = 6379;
  database  = 0;
  password  = "";
  key       = "";
  value     = "";

  // OPTIONAL: GET HOSTNAME
  if ( nrhs >= 2  ) {
    if ( mxIsChar(prhs[0]) ) {
      hostname = (char *) mxCalloc(mxGetN(prhs[0])+1, sizeof(char));
      mxGetString(prhs[0], hostname, mxGetN(prhs[0])+1);
    } else {
      mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Command and Hostname Input must be a string.");
    }
  }

  // OPTIONAL: GET PORT
  if ( nrhs >= 3 ) {
    // GET PORT
    if ( mxIsDouble(prhs[1]) ) {
        // convert double to integer :: PORT
        double* data = mxGetPr(prhs[1]);
        port = (int)floor(data[0]);
    } else {
      mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Command and Hostname Input must be a string and Port must be double.");
    }
  }

  // OPTIONAL: GET DATABASE NR
  if ( nrhs >= 4 ) {
    if ( mxIsDouble(prhs[2]) ) {
      // convert double to integer :: DATABASE NUMBER
      double* databasedata = mxGetPr(prhs[2]);
      database = (int)floor(databasedata[0]);
    } else {
      mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Command and Hostname Input must be a string and Port and database must be double.");
    }
  }

  // OPTIONAL: GET PASSWORD
  if ( nrhs >= 5 ) {
    if ( mxIsChar(prhs[3]) ) {
      password = (char *) mxCalloc(mxGetN(prhs[3])+1, sizeof(char));
      mxGetString(prhs[3], password, mxGetN(prhs[3])+1);
    } else {
      mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Command and Hostname Input must be a string and Port and database must be double.");
    }
  }

  // GET COMMAND & EXECUTE
  if ( nrhs >= 1) {


    // hiredis declaration
    redisContext *c;
    redisReply *reply;

    // 0) MAKE CONNECTION
    struct timeval timeout = { 1, 500000 }; // 1.5 seconds
    c = redisConnectWithTimeout(hostname, port, timeout);
    // error when connection failed
    if (c == NULL || c->err) {
      if (c) {
        mexErrMsgIdAndTxt("MATLAB:redis_:connectionError","Connection error: %s\n", c->errstr);
        redisFree(c);
      } else {
        mexErrMsgIdAndTxt("MATLAB:redis_:connectionError", "Connection error: can't allocate redis context.");
      }
    }

    // 1) OPTIONAL AUTH
    if (strlen(password) > 0){
      reply= redisCommand(c, "AUTH %s", password);
      if (reply->type == REDIS_REPLY_ERROR) {
        /* Authentication failed */
        mexErrMsgIdAndTxt("MATLAB:redis_:AuthenticationFailed", "Authentication failed.");
      }
    }

    // 2) OPTIONAL CHANGE DATABASE NR
    if (database != 0) {
      reply = redisCommand(c, "SELECT %d", database);
      if (reply->type == REDIS_REPLY_ERROR) {
        /* Select database failed */
        mexErrMsgIdAndTxt("MATLAB:redis_:SelectFailed", "Select Database %d failed.", database);
      }
    }

    // --- SINGLE COMMAND OR PIPELINE ---
    // 3) SINGLE COMMAND
    if ( mxIsChar(prhs[nrhs - 1]) ) {
      command = (char *) mxCalloc(mxGetN(prhs[nrhs - 1])+1, sizeof(char));
      mxGetString(prhs[nrhs - 1], command, mxGetN(prhs[nrhs - 1])+1);
      // call redis
      reply = redisCommand(c, command);
      
 

      // check the output
      if (reply->type == REDIS_REPLY_STRING) {
        plhs[0] = mxCreateString(reply->str);
      } else if (reply->type == REDIS_REPLY_ARRAY) {
        // get number of elements
        int n = (int)floor(reply->elements);
        // outout will be a cell array matlab-sided
        cell_array_ptr = mxCreateCellMatrix(n,1);

        for (unsigned int j = 0; j < reply->elements; j++) {
          //mexPrintf("%u) %s\n", j, reply->element[j]->str);
          mxSetCell(cell_array_ptr,j, mxCreateString(reply->element[j]->str));
        }

        // free hiredis
        freeReplyObject(reply);
        redisFree(c);
        plhs[0] = cell_array_ptr;

      } else if (reply->type == REDIS_REPLY_INTEGER) {
        plhs[0] = mxCreateDoubleScalar(reply->integer);
        
        // free redis
        freeReplyObject(reply);
        redisFree(c);
      } else {
        // Laugh in the face of danger
        plhs[0] = mxCreateString(reply->str);
      }



    // 3) PIPELINE ---
    } else if ( mxIsCell(prhs[nrhs - 1]) ){
      //redisReply *reply;
      const mxArray *cell_element_ptr;
      mwIndex n;
      mwSize buflen;
      #ifdef DEBUG
        mwSize m = mxGetNumberOfElements(prhs[nrhs - 1]); 
        mexPrintf("%d cols\n", mxGetN(prhs[nrhs - 1]));
        mexPrintf("%d rows\n", mxGetM(prhs[nrhs - 1]));
        mexPrintf("%d elements\n", m);
      #endif
      int rows = mxGetM(prhs[nrhs - 1]);
      int cols = mxGetN(prhs[nrhs - 1]);
      int reduceCol = 0;
      // PIPELINE
      if (rows > 1){
          // load the silverbullet
          for (int r = 1; r <= rows; r++){
              
              if (cols >= 1) {                             
                  cell_element_ptr = mxGetCell(prhs[nrhs - 1], CMOindex(1, r, rows) - 1);
                  buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
                  command = mxMalloc(buflen);
                  mxGetString(cell_element_ptr, command, buflen);
              } 

              if (cols >= 2) {
                  cell_element_ptr = mxGetCell(prhs[nrhs - 1], CMOindex(2, r, rows) - 1);
                  
                  if (0 == cell_element_ptr) {
                      reduceCol++;
                  } else {
                      buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
                      key = mxMalloc(buflen);
                      mxGetString(cell_element_ptr, key, buflen);
                      if (0 == strlen(key)) { reduceCol++; }
                      mexPrintf("keylen %d\n", strlen(key));
                  }
              }

              if (cols >= 3){
                  cell_element_ptr = mxGetCell(prhs[nrhs - 1], CMOindex(3, r, rows) - 1);
                  if (0 == cell_element_ptr) {
                      reduceCol++;
                  } else {
                      buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
                      value = mxMalloc(buflen);
                      mxGetString(cell_element_ptr, value, buflen);
                      if (0 == strlen(value)) { reduceCol++;}
                      mexPrintf("valuelen %d\n", strlen(value));
                  }
              }
              //#ifdef DEBUG
                    mexPrintf("pipeline: c %s k %s v %s\n", command, key, value);
              //#endif // DEBUG
              if ((cols - reduceCol) == 1) {
                redisAppendCommand(c, command);
              } else if ((cols - reduceCol) == 2) {
                redisAppendCommand(c, "%s %s", command, key);
              } else if ((cols - reduceCol) == 3) {
                redisAppendCommand(c, "%s %s %s", command, key, value);
              }
              reduceCol = 0;
              command = "";
              key = "";
              value = "";
              
             
          }
          
          // fire the silverbullet
          for (n = 0; n < rows; n++) {
              redisGetReply(c, (void**)&reply);
              freeReplyObject(reply);
          }
          plhs[0] = mxCreateString("OK");
          
          redisFree(c);
          
      // SINGLE COMMAND, WHITESPACE SAFE
      } else {
          if (cols >= 1){
              
              cell_element_ptr = mxGetCell(prhs[nrhs - 1], 0);
              #ifdef DEBUG
                mexPrintf("command len: %d\n", mxGetN(cell_element_ptr));
              #endif // DEBUG
              buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
              command = mxMalloc(buflen);
              mxGetString(cell_element_ptr, command, buflen);
              
              #ifdef DEBUG
                mexPrintf("command: %s\n", command);
              #endif // DEBUG
              
          } 
          
          if (cols >= 2){
              
              cell_element_ptr = mxGetCell(prhs[nrhs - 1], 1);
              #ifdef DEBUG
                mexPrintf("key len: %d\n", mxGetN(cell_element_ptr));
              #endif // DEBUG
              buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
              key = mxMalloc(buflen);
              mxGetString(cell_element_ptr, key, buflen);
              
              #ifdef DEBUG
                mexPrintf("key: %s\n", key);
              #endif // DEBUG
              
          } 
          
          if (cols >= 3){
              
              cell_element_ptr = mxGetCell(prhs[nrhs - 1], 2);
              #ifdef DEBUG
                mexPrintf("value len: %d\n", mxGetN(cell_element_ptr));
              #endif // DEBUG
              buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
              value = mxMalloc(buflen);
              mxGetString(cell_element_ptr, value, buflen);
              
              #ifdef DEBUG
                mexPrintf("value: %s\n", value);
              #endif // DEBUG
              
          }
          
          #ifdef DEBUG
                mexPrintf("%s %s %s\n", command, key, value);
          #endif // DEBUG
          // call redis
          if (cols == 1) {
            reply = redisCommand(c, command);
          } else if (cols == 2) {
            reply = redisCommand(c, "%s %s", command, key);
          } else if (cols == 3) {
            reply = redisCommand(c, "%s %s %s", command, key, value);
          }



          // check the output
          if (reply->type == REDIS_REPLY_STRING) {
            plhs[0] = mxCreateString(reply->str);
          } else if (reply->type == REDIS_REPLY_ARRAY) {
            // get number of elements
            int n = (int)floor(reply->elements);
            // outout will be a cell array matlab-sided
            cell_array_ptr = mxCreateCellMatrix(n,1);

            for (unsigned int j = 0; j < reply->elements; j++) {
              //mexPrintf("%u) %s\n", j, reply->element[j]->str);
              mxSetCell(cell_array_ptr,j, mxCreateString(reply->element[j]->str));
            }

            // free hiredis
            freeReplyObject(reply);
            redisFree(c);
            plhs[0] = cell_array_ptr;

          } else if (reply->type == REDIS_REPLY_INTEGER) {
            plhs[0] = mxCreateDoubleScalar(reply->integer);

            // free redis
            freeReplyObject(reply);
            redisFree(c);
          } else {
            // Laugh in the face of danger
            plhs[0] = mxCreateString(reply->str);
          }
          
            
      }

    } else {
      mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Command Input must be a string.");
    }
  }

}


