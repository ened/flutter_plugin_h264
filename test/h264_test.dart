import 'package:flutter_test/flutter_test.dart';
import 'package:h264/h264.dart';
import 'package:mockito/annotations.dart';

import 'h264_test.mocks.dart';

@GenerateMocks([H264])
void main() {
  group("singleton pattern", () {
    test("It always return the same instance", () {
      final instance1 = H264();
      final instance2 = H264();

      expect(instance1 == instance2, true);
    });
  });

  group('setInstance', () {
    test('should set the instance', () {
      final mock = MockH264();
      H264.setInstance(mock);
      expect(H264(), mock);
    });
  });
}
