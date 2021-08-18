import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class H264 {
  factory H264() {
    return _instance ??= H264.private(
      const MethodChannel('asia.ivity.flutter/h264'),
    );
  }

  @visibleForTesting
  H264.private(this._channel);

  @visibleForTesting
  static void setInstance(H264? instance) {
    _instance = instance;
  }

  static H264? _instance;

  final MethodChannel _channel;

  /// Decode a single H.264 frame (IDR) from [source] into the [target] path.
  /// The decoder currently requires knowledge of the source frames [width] and [height].
  ///
  /// This Future will throw an error if decoding fails.
  Future<void> decodeFrame(
      String source, String target, int width, int height) async {
    final params = {
      "source": source,
      "target": target,
      "width": width,
      "height": height,
    };

    await _channel.invokeMethod<void>('decode', params);
  }
}
