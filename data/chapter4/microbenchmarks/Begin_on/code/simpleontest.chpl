use Time, Random, MonteCarlo;

proc main() {
  var t = new Timer();
  t.start();
  while(t.elapsed() < 20){}
  t.stop();
  var total = new Timer();
  total.start();

	on Locales[1] do begin{
		monteCarlo();
		on Locales[2] do begin{
			monteCarlo();
		}
	}
  total.stop();
  writeln("Total elapsed:", total.elapsed()); 
}
