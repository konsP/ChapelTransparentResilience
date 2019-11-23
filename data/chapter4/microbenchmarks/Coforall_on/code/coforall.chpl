use Time, Random, MonteCarlo;

proc main() {
  var t = new Timer();
  t.start();
  while(t.elapsed() < 20){}
  t.stop();
  var total = new Timer();
  total.start();

	coforall loc in Locales{
		on loc do
			monteCarlo();
	}
	total.stop();
  writeln("Total elapsed:", total.elapsed());
}

