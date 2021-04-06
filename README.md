# h264

A simple Flutter plugin which decodes raw H264 or H265 IDR frames into bitmap representations.

It's the callers responsibility to check whether the hardware supports the input format & dimensions.

The plugin utilizes platform code and does not depend on 3rd party libraries.
This means in most cases, the hardware decoder is used to carry out the conversion.