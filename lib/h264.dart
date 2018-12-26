import 'dart:async';

import 'package:flutter/services.dart';

class H264 {
  static const MethodChannel _channel =
      const MethodChannel('asia.ivity.flutter/h264');

  /// Decode a single H.264 frame (IDR) from [source] into the [target] path.
  /// The decoder currently requires knowledge of the source frames [width] and [height].
  ///
  /// This Future will throw an error if decoding fails.
  static Future<void> decodeFrame(
      String source, String target, int width, int height) async {
    final params = {
      "source": source,
      "target": target,
      "width": width,
      "height": height,
    };

    await _channel.invokeMethod('decode', params);
  }
}
