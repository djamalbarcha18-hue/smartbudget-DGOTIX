import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no pig-shaped "savings" icon anywhere: the money box instead', () {
    final RegExp pig = RegExp(r'Icons\.savings');
    final List<String> found = <String>[
      for (final FileSystemEntity f
          in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            pig.hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(found, isEmpty);
  });
}
