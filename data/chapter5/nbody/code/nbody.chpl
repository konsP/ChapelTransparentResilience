use BlockDistResMultiTaskRecovery, Morebodies;
//
// The number of timesteps to simulate; may be set via the command-line
//
config const n = 10000;

//
// the number of bodies to be simulated
//
const numbodies = bodies.numElements;

const MonoSpace = {1..#numbodies};
var MonoLocaleView={0..#numLocales};
var MyMonoLocales:[MonoLocaleView] locale = reshape(Locales, MonoLocaleView);
const ProblemSpace => MonoSpace dmapped Block(boundingBox=MonoSpace, targetLocales=MyMonoLocales);

var A: [ProblemSpace] body;
var C: [MonoSpace] body =bodies;
//
// The computation involves initializing the sun's velocity,
// writing the initial energy, advancing the system through 'n'
// timesteps, and writing the final energy.
//
proc main() {
	
  var t, total = new Timer();
  t.start();
  while(t.elapsed() <20){} 
  t.stop();
	
  initArrays();
  initSun();
  
  total.start();
  
  writef("%.9r\n", energy());
  for 1..n do
    advance(0.01);
  var finalEnergy = energy();  
  writef("%.9r\n", finalEnergy);
  
  total.stop();
	verifyResults(finalEnergy);

  writeln("Configuration: numbodies= ", numbodies, " n=", n);
  writeln("Total elapsed: ", total.elapsed(), "\n\n");
}

//
// compute the sun's initial velocity
//
proc initSun() {
  const p = + reduce (for b in bodies do (b.v * b.mass));
  bodies[1].v = -p / solarMass;
}

proc initArrays() {
  for i in 1..numbodies {
	  A[i] = bodies[i];
  } 
  if debug then printArrays();
}

//
// advance the positions and velocities of all the bodies
//
proc advance(dt) {
  
  forall i in 1..numbodies {
    forall j in i+1..numbodies {
      ref b1 = A[i],
          b2 = A[j];

      const dpos = b1.pos - b2.pos,
            mag = dt / sqrt(sumOfSquares(dpos))**3;
            
      b1.v -= dpos * b2.mass * mag;
      b2.v += dpos * b1.mass * mag;
    }
  }
  
  for b in A do
    b.pos += dt * b.v;
}

//
// compute the energy of the bodies
//
proc energy() {
  var e = 0.0;
  
  for i in 1..numbodies {
    const b1 = A[i];
    
    e += 0.5 * b1.mass * sumOfSquares(b1.v);
    
    for j in i+1..numbodies {
      const b2 = A[j];
      
      e -= (b1.mass * b2.mass) / sqrt(sumOfSquares(b1.pos - b2.pos));
    }
  }
  
  return e;
}

proc verifyResults(finalEnergy) {
	
	writef("%.9r\n", energyC());
	for 1..n do {
		
		for i in 1..numbodies {
			for j in i+1..numbodies {
				ref b1 = C[i],
					b2 = C[j];

				const dpos = b1.pos - b2.pos,
					mag = 0.01 / sqrt(sumOfSquares(dpos))**3;
            
				b1.v -= dpos * b2.mass * mag;
				b2.v += dpos * b1.mass * mag;
			}	
		}
  
		for b in C do
			b.pos += 0.01 * b.v;
	}
	var xx = energyC();
	writef("%.9r\n", xx);
	
	if(xx == finalEnergy) then
		writeln("Verify: Success " );
	else
		writeln("Verify: Failed " );
}

proc energyC() {
  var e = 0.0;
  
  for i in 1..numbodies {
    const b1 = C[i];
    
    e += 0.5 * b1.mass * sumOfSquares(b1.v);
    
    for j in i+1..numbodies {
      const b2 = C[j];
      
      e -= (b1.mass * b2.mass) / sqrt(sumOfSquares(b1.pos - b2.pos));
    }
  }
  
  return e;
}

//
// a helper routine to compute the sum of squares of a 3-tuple's components
//
inline proc sumOfSquares(x)
  return x(1)**2 + x(2)**2 + x(3)**2;
