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

//#define DEBUG

// declarate some stuff
char* redisReturn;
char *hostname, *command, *password, *key, *value, *tmp;
bool key_value = false;
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

  // OPTIONAL: GET KEY & value
  if ( nrhs >= 7 ) {
    key_value = true;
    if ( mxIsChar(prhs[4]) && mxIsChar(prhs[5]) ) {
      key = (char *) mxCalloc(mxGetN(prhs[4])+1, sizeof(char));
      mxGetString(prhs[4], key, mxGetN(prhs[4])+1);

      value = (char *) mxCalloc(mxGetN(prhs[5])+1, sizeof(char));
      mxGetString(prhs[5], value, mxGetN(prhs[5])+1);
    } else {
      mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Supplied key/value must be a strings.");
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
      if (!key_value) {
        reply = redisCommand(c, command);
      } else {
        reply = redisCommand(c, command, key, value);
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
        long long int t = reply->integer;
        // save copy
        //snprintf(redisChar, 19, "%lld",t);
        //plhs[0] = mxCreateString(redisChar);

        plhs[0] = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, mxREAL);
        double *out;
        out = mxGetPr(plhs[0]);
        out[0] = t;

        // free redis
        freeReplyObject(reply);
        redisFree(c);
      } else {
        // Laugh in the face of danger
        plhs[0] = mxCreateString(reply->str);
      }// #define DEBUG



    // 3) PIPELINE ---
    } else if ( mxIsCell(prhs[nrhs - 1]) ){
      //redisReply *reply;
      const mxArray *cell_element_ptr;
      char* c_array;
      mwIndex n;
      mwSize m, buflen;
      m = mxGetNumberOfElements(prhs[nrhs - 1]);
      int status;

      // load the silverbullet
      for (n = 0; n < m; n++){
        cell_element_ptr = mxGetCell(prhs[nrhs - 1],n);
        buflen = mxGetN(cell_element_ptr)*sizeof(mxChar)+1;
        c_array = mxMalloc(buflen);
        status = mxGetString(cell_element_ptr,c_array,buflen);
        redisAppendCommand(c, c_array);
        #ifdef DEBUG
          mexPrintf("pipeline command: %s\n", c_array);
        #endif // DEBUG
      }

      // fire the silverbullet
      for (n = 0; n < m; n++) {
        redisGetReply(c, (void**)&reply);
        freeReplyObject(reply);
      }
      plhs[0] = mxCreateString("OK");

      redisFree(c);

    } else {
      mexErrMsgIdAndTxt("MATLAB:redis_:nrhs", "Command Input must be a string.");
    }
  }

}


