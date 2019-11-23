module MonteCarlo{

	proc monteCarlo(){
	  const      n = 100000000,    // number of random points to try
		     seed = 589494289; // seed for random number generator
	
	  var rs = new RandomStream(seed, parSafe=false);
	  var count = 0;
	  for i in 1..n do
  	    if (rs.getNext()**2 + rs.getNext()**2) <= 1.0 then
		count += 1;
	  var pi =count * 4.0 / n;
	  writeln("pi=", pi, " on locale ", here.id);
	  delete rs;
	}
}
