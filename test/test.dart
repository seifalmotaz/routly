import 'package:routly/routly.dart';
import 'package:test/test.dart';

void main() {
  test('Basic', () {
    final r = Routly();
    r.add('/users', 0);
    r.add('/users/{id}', 1);
    r.sort();
    final v = r.match('/users/');
    expect(v.$2, 0);
    final v2 = r.match('/users/1');
    expect(v2.$2, 1);
    expect(v2.$1['id'], '1');
  });
}
