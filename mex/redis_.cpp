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

// The C++ class handle allowing us to reuse opened redis connections
#include "class_handle.hpp"

//#define DEBUG

// declarate some stuff
char* redisReturn;
char instruction[64];
char *hostname, *command, *password, *key, *value;
int port, database;
char redisChar[19]; // afaik long enough for long long int
mxArray *cell_array_ptr;

// matlab/octave mex function
void mexFunction (int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
  // --- input checks
  // currently we need at least more than two inputs and one ouput!!
  // improve me!!
  if (nrhs < 1 && nlhs != 1) {
    mexErrMsgIdAndTxt( "MATLAB:redis_:invalidNumInputs",
                      "One or more inputs are required.");
  }

  // first input is an instruction string telling us what to do
  if (nrhs < 1 || mxGetString(prhs[0], instruction, sizeof(instruction)))
    mexErrMsgTxt("First input should be an instruction string less than 64 characters long.");

  // Valid instructions are
  //  new     - create a new redis connection
  //  delete  - delete the current connection
  //  command - send a redis command to the server
  if (!strcmp("new", instruction)) {
    // default stuff
    char *hostname  = (char*)"127.0.0.1";
    port      = 6379;
    database  = 0;
    char *password  = (char*)"";

    // OPTIONAL: GET HOSTNAME
    if ( nrhs >= 2  ) {
      if ( mxIsChar(prhs[1]) ) {
        hostname = (char *) mxCalloc(mxGetN(prhs[1])+1, sizeof(char));
        mxGetString(prhs[1], hostname, mxGetN(prhs[1])+1);
      } else {
        mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Error setting up redis connection: Hostname must be a string.");
      }

    }

    // OPTIONAL: GET PORT
    if ( nrhs >= 3 ) {
      // GET PORT
      if ( mxIsDouble(prhs[2]) ) {
          // convert double to integer :: PORT
          double* data = mxGetPr(prhs[2]);
          port = (int)floor(data[0]);
      } else {
        mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Error setting up redis connection: Port must be a double.");
      }
    }

    // OPTIONAL: GET DATABASE NR
    if ( nrhs >= 4 ) {
      if ( mxIsDouble(prhs[3]) ) {
        // convert double to integer :: DATABASE NUMBER
        double* databasedata = mxGetPr(prhs[3]);
        database = (int)floor(databasedata[0]);
      } else {
        mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Error setting up redis connection: Database must be double.");
      }
    }

    // OPTIONAL: GET PASSWORD
    if ( nrhs >= 5 ) {
      if ( mxIsChar(prhs[4]) ) {
        password = (char *) mxCalloc(mxGetN(prhs[4])+1, sizeof(char));
        mxGetString(prhs[4], password, mxGetN(prhs[4])+1);
      } else {
        mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Error setting up redis connection: Password must be a string.");
      }
    }

    // MAKE THE REDIS CONNECTION
    redisContext *c;

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
      redisReply *reply;
      reply = (redisReply*)redisCommand(c, "AUTH %s", password);
      if (reply->type == REDIS_REPLY_ERROR) {
        /* Authentication failed */
        mexErrMsgIdAndTxt("MATLAB:redis_:AuthenticationFailed", "Authentication failed.");
      }
      freeReplyObject(reply);
    }

    // 2) OPTIONAL CHANGE DATABASE NR
    if (database != 0) {
      redisReply *reply;
      reply = (redisReply*)redisCommand(c, "SELECT %d", database);
      if (reply->type == REDIS_REPLY_ERROR) {
        /* Select database failed */
        mexErrMsgIdAndTxt("MATLAB:redis_:SelectFailed", "Select Database %d failed.", database);
      }
      freeReplyObject(reply);
    }

    // 3) STORE THE CONNECTION & RETURN IT
    plhs[0] = convertPtr2Mat<redisContext>(c);
    return;

  } else if (!strcmp("delete", instruction)) {

    if ( nrhs < 2 ) {
      mexErrMsgTxt("No redis connection supplied after delete instruction (expecting the handle)");
    }

    // Safely destroy the C++ object
    try {
      redisContext *c = convertMat2Ptr<redisContext>(prhs[1]);
      redisFree(c);
      destroyObject<redisContext>(prhs[1]);
    } catch (int e) {

    }
    // Warn if other commands were ignored
    if (nlhs != 0 || nrhs != 2)
      mexWarnMsgTxt("Delete: Unexpected arguments ignored.");
    return;

  } else if (!strcmp("command", instruction)) {

    if ( nrhs < 2 ) {
      mexErrMsgTxt("No redis connection supplied (expecting the handle)");
    } else if ( nrhs < 3 ) {
      mexErrMsgTxt("No redis command supplied");
    }

    // Get the class instance pointer from the second input
    redisContext *c = convertMat2Ptr<redisContext>(prhs[1]);
    redisReply *reply;

    // --- SINGLE COMMAND OR PIPELINE ---
    // 3) SINGLE COMMAND
    if ( mxIsChar(prhs[nrhs - 1]) ) {
      command = (char *) mxCalloc(mxGetN(prhs[nrhs - 1])+1, sizeof(char));
      mxGetString(prhs[nrhs - 1], command, mxGetN(prhs[nrhs - 1])+1);
      // call redis
      reply = (redisReply*)redisCommand(c, command);



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
        plhs[0] = cell_array_ptr;

      } else if (reply->type == REDIS_REPLY_INTEGER) {
        plhs[0] = mxCreateDoubleScalar(reply->integer);

        // free redis
        freeReplyObject(reply);
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
                  command = (char *)mxMalloc(buflen);
                  mxGetString(cell_element_ptr, command, buflen);
              }

              if (cols >= 2) {
              
                  cell_element_ptr = mxGetCell(prhs[nrhs - 1], CMOindex(2, r, rows) - 1);
                  // matlab check
                  if (0 == cell_element_ptr)  {
                      reduceCol++;
                  } else {
                      // octave check
                      buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
                      if (1 >= buflen) {
                          reduceCol++;
                      } else {
                          key = (char *)mxMalloc(buflen);
                          mxGetString(cell_element_ptr, key, buflen);
                     }
                  }
              }

              if (cols >= 3){
              
                  cell_element_ptr = mxGetCell(prhs[nrhs - 1], CMOindex(3, r, rows) - 1);
                  // matlab check
                  if (0 == cell_element_ptr) {
                      reduceCol++;
                  } else {
                      // octave check
                      buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
                      if (1 >= buflen) {
                          reduceCol++;
                      } else {
                          value = (char *)mxMalloc(buflen);
                          mxGetString(cell_element_ptr, value, buflen);
                      }
                  }
              }
              #ifdef DEBUG
                mexPrintf("pipeline: c %s k %s v %s\n", command, key, value);
              #endif // DEBUG
              if ((cols - reduceCol) == 1) {
                redisAppendCommand(c, command);
                mxFree(command);
              } else if ((cols - reduceCol) == 2) {
                redisAppendCommand(c, "%s %s", command, key);
                mxFree(command);
                mxFree(key);
              } else if ((cols - reduceCol) == 3) {
                redisAppendCommand(c, "%s %s %s", command, key, value);
                mxFree(command);
                mxFree(key);
                mxFree(value);
              }
              reduceCol = 0;

          }

          // fire the silverbullet
          for (n = 0; n < rows; n++) {
              redisGetReply(c, (void**)&reply);
              freeReplyObject(reply);
          }
          plhs[0] = mxCreateString("OK");

      // SINGLE COMMAND, WHITESPACE SAFE
      } else {

          int cols = mxGetN(prhs[nrhs - 1]);
          if (cols >= 1){

              cell_element_ptr = mxGetCell(prhs[nrhs - 1], 0);
              buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
              command = (char *)mxMalloc(buflen);
              mxGetString(cell_element_ptr, command, buflen);

              #ifdef DEBUG
                mexPrintf("command: %s\n", command);
              #endif // DEBUG

          }

          if (cols >= 2){

              cell_element_ptr = mxGetCell(prhs[nrhs - 1], 1);
              buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
              key = (char *)mxMalloc(buflen);
              mxGetString(cell_element_ptr, key, buflen);

              #ifdef DEBUG
                mexPrintf("key: %s\n", key);
              #endif // DEBUG

          }

          if (cols >= 3){

              cell_element_ptr = mxGetCell(prhs[nrhs - 1], 2);
              buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
              value = (char *)mxMalloc(buflen);
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
            reply = (redisReply*)redisCommand(c, command);
          } else if (cols == 2) {
            reply = (redisReply*)redisCommand(c, "%s %s", command, key);
          } else if (cols == 3) {
            reply = (redisReply*)redisCommand(c, "%s %s %s", command, key, value);
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
            plhs[0] = cell_array_ptr;

          } else if (reply->type == REDIS_REPLY_INTEGER) {
            plhs[0] = mxCreateDoubleScalar(reply->integer);

            // free redis
            freeReplyObject(reply);
          } else {
            // Laugh in the face of danger
            plhs[0] = mxCreateString(reply->str);
          }


      }

    } else {
      mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Command Input must be a string.");
    }

  } else {
    mexErrMsgTxt("Unknown redis instruction expecting one of (new, delete, command)");
  }

}


