//
// Use standard modules for Block distributions, Timing routines, Type
// utility functions, and Random numbers
//
use BlockDistResMultiTaskRecovery, Time, Types, Random;

//
// Use shared user module for computing HPCC problem sizes
//

use HPCCProblemSize;

//
// The number of vectors and element type of those vectors
//
const numVectors = 3;
type elemType = real(64);

//
// Configuration constants to set the problem size (m) and the scalar
// multiplier, alpha
//
config const m = 400,//computeProblemSize(numVectors, elemType),
             alpha = 3.0,// /** change back to 3 when done*/
             printDbg = false;
             

//
// Configuration constants to set the number of trials to run and the
// amount of error to permit in the verification
//
config const numTrials = 1,
             epsilon = 0.0;

//
// Configuration constants to indicate whether or not to use a
// pseudo-random seed (based on the clock) or a fixed seed; and to
// specify the fixed seed explicitly
//
config const useRandomSeed = true,

             seed = if useRandomSeed then SeedGenerator.currentTime else 314159265;

//
// Configuration constants to control what's printed -- benchmark
// parameters, input and output arrays, and/or statistics
//
config const printParams = true,
             printArrays = false,
             printStats = true;

//
// The program entry point
//
proc main() {
  printConfiguration();   // print the problem size, number of trials, etc.
  
  var t, tt = new Timer();
  t.start();
  while(t.elapsed() <20){} //20
  t.stop();

  //
  // ProblemSpace describes the index set for the three vectors.  It
  // is a 1D domain that is distributed according to a Block
  // distribution.  In this case, the Block distribution is 1D
  // distribution computed by blocking the bounding box 1..m across
  // the set of locales.  The ProblemSpace domain also contains the
  // indices 1..m.
  //  
  const MonoSpace = {1..m};
  var MonoLocaleView={0..#numLocales};
  var MyMonoLocales:[MonoLocaleView] locale = reshape(Locales, MonoLocaleView);
  const ProblemSpace => MonoSpace dmapped Block(boundingBox=MonoSpace, targetLocales=MyMonoLocales);


  //
  // A, B, and C are the three distributed vectors, declared to store
  // a variable of type elemType for each index in ProblemSpace.
  //
  var A, B, C: [ProblemSpace] elemType;
  /**	n-elements*2 dsiAccesses - can we optimize this? dsiAccess called anyway - not a part of the resilience framework we have only added some capabilities for resilience updates*/
  
	initVectors(B, C);    

	var execTime: [1..numTrials] real;                 // an array of timings
  	
	for trial in 1..numTrials {                        // loop over the trials
		const startTime = getCurrentTime();              // capture the start time
		if(printDbg) then writeln("Trial #", trial);
		//
		// The main loop: Iterate over the vectors A, B, and C in a
		// parallel, zippered manner storing the elements as a, b, and c.
		// Compute the multiply-add on b and c, storing the result to a.
		//
   
		forall (a, b, c) in zip(A, B, C) do {    
		a = b + alpha * c;   
		}
		execTime(trial) = getCurrentTime() - startTime;  // store the elapsed time
	}

  // writeln("\n--- verification---");
  // prettyPrint(ProblemSpace, A);
   
   //if(printDbg) then writeln("--- timing---");
   printTimes(execTime);

   var v = verifyResults(A, B, C);
   writeln("Verification = ", v, "\n");
}

proc prettyPrint(space, A){
	
	var count =1;
	for i in space do{
		if (i<count*1000000) then{
			write( A[i], " ");
		}else{
			write("   on ", A[i].locale.id, "\n\n");
			count=count+1;
		}
	}
}

//
// Print the problem size and number of trials
//
proc printConfiguration() {
  if (printParams) {
    if (printStats) then printLocalesTasks();
    printProblemSize(elemType, numVectors, m);
    writeln("Number of trials = ", numTrials, "\n");
  }
}

//
// Initialize vectors B and C using a random stream of values and
// optionally print them to the console
//
proc initVectors(B, C) {
  var randlist = new RandomStream(seed);

  randlist.fillRandom2(B);
  randlist.fillRandom2(C);

  if (printArrays) {
    writeln("B is: ", B);
	writeln("C is: ", C );
  
	writeln("--- B");
	for b in B do
		writeln(b.locale.id);
	
	writeln("--- C");
	for c in C do
		writeln(c.locale.id);
  }
  delete randlist;
}

//
// Verify that the computation is correct
//
proc verifyResults(A, B, C) {
  if (printArrays) then writeln("A is:     ", A, "\n");  // optionally print A

  //
  // recompute the computation, destructively storing into B to save space
  //
  forall (b, c) in zip(B, C) do
    b += alpha *c;  

  if (printArrays) then writeln("A-hat is: ", B, "\n");  // and A-hat too

  //
  // Compute the infinity-norm by computing the maximum reduction of 
  // the absolute value of A's elements minus the new result 
  // computed in B. "[i in I]" represents an expression-level 
  // loop: "forall i in I"
  //
  const infNorm = max reduce [(a,b) in zip(A,B)] abs(a - b);

  return (infNorm <= epsilon);    // return whether the error is acceptable
}

//
// Print out success/failure, the timings, and the GB/s value
//
proc printResults(successful, execTimes) {
  writeln("Validation: ", if successful then "SUCCESS" else "FAILURE");
  if (printStats) {
    const totalTime = + reduce execTimes,
          avgTime = totalTime / numTrials,
          minTime = min reduce execTimes;
    writeln("Execution time:");
    writeln("  tot = ", totalTime);
    writeln("  avg = ", avgTime);
    writeln("  min = ", minTime);

    const GBPerSec = numVectors * numBytes(elemType) * (m / minTime) * 1e-9;
    writeln("Performance (GB/s) = ", GBPerSec);
  }
}

proc printTimes(execTimes) {
  if (printStats) {
    const totalTime = + reduce execTimes,
          avgTime = totalTime / numTrials,
          minTime = min reduce execTimes;
    writeln("Execution time:");
    writeln("  tot = ", totalTime);
    writeln("  avg = ", avgTime);
    writeln("  min = ", minTime);

    const GBPerSec = numVectors * numBytes(elemType) * (m / minTime) * 1e-9;
    writeln("Performance (GB/s) = ", GBPerSec);
  }
}
