import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves every screenshot the marketing test takes into screenshots/.
Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes,
          [Map<String, Object?>? args]) async {
        final File f = File('screenshots/$name.png');
        await f.create(recursive: true);
        await f.writeAsBytes(bytes);
        return true;
      },
    );
