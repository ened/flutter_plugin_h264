# h264_example

Demonstrates how to use the h264 plugin.

## Getting Started

This project ships with a few H264 sample files, which will be handed to the platform for decoding.

## Running integration tests

The integration test suite converts a few standard H264 frames to JPG.

```
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/h264_test.dart
```