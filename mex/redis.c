// compile hint

/*
 * MATLAB
 * mex -lhiredis -I/usr/include/hiredis/ CFLAGS='-Wall -Wextra -fPIC -std=c99 -O4 -pedantic -g' redis.c
 *
 * GNU OCTAVE
 * gcc -fPIC -I /usr/include/octave-3.8.2/octave/ -lm -I /usr/include/hiredis/ -lhiredis -shared redis.c -o redis.mex
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

// preallocate some stuff
char* redisReturn;
char *hostname;
int port;
char *command;


// call Redis function
char* callRedis(const char *hostname, int port, char *command){

  // hiredis declaration
  redisContext *c;
  redisReply *reply;

  // time out and make redis connection
  struct timeval timeout = { 1, 500000 }; // 1.5 seconds
  c = redisConnectWithTimeout(hostname, port, timeout);

  // error when connection failed
  if (c == NULL || c->err) {
    if (c) {
      mexErrMsgIdAndTxt("MATLAB:redis:connectionError","Connection error: %s\n", c->errstr);
      redisFree(c);
    } else {
      mexErrMsgIdAndTxt("MATLAB:redis:connectionError", "Connection error: can't allocate redis context.");
    }
    //exit(1);
  }

  reply = redisCommand(c, command);
  //freeReplyObject(reply);

  /* Disconnects and frees the context */
  //redisFree(c);

  return reply->str;
}


// matlab/octave mex function
void mexFunction (int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{

  // --- input checks
  // currently we need at least more than one input and one ouput!!
  // improve me!!
  if(nrhs < 1 && nlhs != 1) {
    mexErrMsgIdAndTxt( "MATLAB:lua:invalidNumInputs",
                      "One or more inputs are required.");


  } else if ( nrhs == 1) {
    // one input (command), use default host and port
    if ( !mxIsChar(prhs[0]) ) {
      mexErrMsgIdAndTxt("MATLAB:redis:nrhs", "Command Input must be a string.");
    } else {

      hostname = "127.0.0.1";
      port = 6379;
      command = (char *) mxCalloc(mxGetN(prhs[0])+1, sizeof(char));
      mxGetString(prhs[0], command, mxGetN(prhs[0])+1);

      redisReturn = callRedis(hostname, port, command);

      plhs[0] = mxCreateString(redisReturn);


    }
    
  } else if ( nrhs == 2  ) {
      // two inputs (0. host, 1. command)
      if ( !mxIsChar(prhs[0])  ||  !mxIsChar(prhs[1]) ) {
          mexErrMsgIdAndTxt("MATLAB:lua:nrhs", "Command and Hostname Input must be a string.");
      } else {
          
          port = 6379;
          
          hostname = (char *) mxCalloc(mxGetN(prhs[0])+1, sizeof(char));
          mxGetString(prhs[0], hostname, mxGetN(prhs[0])+1);
          
          command = (char *) mxCalloc(mxGetN(prhs[1])+1, sizeof(char));
          mxGetString(prhs[1], command, mxGetN(prhs[1])+1);
          
          redisReturn = callRedis(hostname, port, command);
          
          plhs[0] = mxCreateString(redisReturn);
          
      }
  } else if ( nrhs == 3 ) {
      // three inputs (0. host, 1. port, 2. command)
      if ( !mxIsChar(prhs[0])  ||  !mxIsDouble(prhs[1]) || !mxIsChar(prhs[2]) ) {
          mexErrMsgIdAndTxt("MATLAB:lua:nrhs", "Command and Hostname Input must be a string and Port must be double.");
      } else {
          
          
          
          hostname = (char *) mxCalloc(mxGetN(prhs[0])+1, sizeof(char));
          mxGetString(prhs[0], hostname, mxGetN(prhs[0])+1);
          
          double* data = mxGetPr(prhs[1]);
          port = (int)floor(data[0]);

          command = (char *) mxCalloc(mxGetN(prhs[2])+1, sizeof(char));
          mxGetString(prhs[2], command, mxGetN(prhs[2])+1);
          
          redisReturn = callRedis(hostname, port, command);
          
          plhs[0] = mxCreateString(redisReturn);
          
      }
  }
}


