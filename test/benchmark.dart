import 'package:routly/routly.dart';

void main() {
  // syncBenchmark('Basic', () {
  Stopwatch stopwatch = Stopwatch();
  final r = Routly();
  r.add('/users', 0);
  r.add('/users/{id}', 1);
  r.sort();
  stopwatch.start();
  r.match('/users/');
  // assert(v.$2 == 0);

  stopwatch.start();
  r.match('/users/1578');
  stopwatch.stop();
  print(stopwatch.elapsedMicroseconds);
  print(stopwatch.elapsedMilliseconds);
  // assert(v2.$2 == 1);
  // assert(v2.$1['id'] == '1');
  // }).report();
}
