use Time, Random, MonteCarlo;

proc main() {
  var t = new Timer();
  t.start();
  while(t.elapsed() < 20){}
  var total = new Timer();
  total.start();

  on Locales[1] do  {
    monteCarlo();
    on Locales[2] do{
      monteCarlo();
    }
  }
  total.stop();
  writeln("Total elapsed:", total.elapsed());
}

