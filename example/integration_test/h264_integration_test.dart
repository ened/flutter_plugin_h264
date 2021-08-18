import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h264/h264.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

class Sample {
  final String name;
  final int width;
  final int height;

  Sample(this.name, this.width, this.height);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (Sample asset in [
    Sample("180206_120601_001_LO.MP4.thumbnail.h264", 768, 432),
    Sample("180304_163039_357.mov.thumbnail.h264", 1920, 1080),
  ]) {
    testWidgets('convert ${asset.name}', (WidgetTester tester) async {
      final loaded = await rootBundle.load("assets/samples/${asset.name}");

      final tmp = await getTemporaryDirectory();
      final tmpAsset = File("${tmp.path}/cached-${asset.name}");
      tmpAsset.writeAsBytesSync(loaded.buffer.asUint8List());

      final tmpOut = File("${tmp.path}/decoded-${asset.name}.jpg");

      try {
        tmpOut.deleteSync();
      } catch (_) {}

      await H264().decodeFrame(
        tmpAsset.path,
        tmpOut.path,
        asset.width,
        asset.height,
      );

      expect(tmpOut.lengthSync(), isNonZero);
    });
  }
}
