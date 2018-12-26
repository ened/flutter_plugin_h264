package asia.ivity.h264.util;

import android.graphics.Bitmap;
import android.media.MediaCodec;
import android.media.MediaFormat;
import java.io.InputStream;
import java.nio.ByteBuffer;

/**
 */

public class H264Reader {
    
    /**
     * Decode a H264 frame into a Android Bitmap.
     *
     * @param is     Input Stream
     * @param length Input stream length (e.g. file size) in bytes
     * @param width  H264 frame width.
     * @param height H264 frame height.
     * @return Android bitmap or <code>null</code> if the decoding failed.
     * @throws Exception For any underlying issues.
     */
    public synchronized static Bitmap decode(InputStream is, long length, int width, int height) throws Exception {
//        Log.d(TAG,"decode: %d bytes for resolution: %d x %d, thread: %s", length, width, height, Thread.currentThread());

        int codecHeight = height + (16 - height % 16);

        OutputSurface outputSurface = new OutputSurface(width, codecHeight);

        MediaFormat format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, codecHeight);

        MediaCodec codec = MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_VIDEO_AVC);

        codec.configure(format, outputSurface.getSurface(), null, 0);

//        Log.d(TAG,"outputFormat: %s", codec.getOutputFormat());

        codec.start();

        long timeoutUs = 1000000;

        for (; ; ) {
            int inputBufferId = codec.dequeueInputBuffer(timeoutUs);

//            Log.d(TAG,"inputBufferId: %d", inputBufferId);

            if (inputBufferId >= 0) {
                ByteBuffer inputBuffer = codec.getInputBuffer(inputBufferId);
                if (inputBuffer == null) {
                    continue;
                }

                byte[] buffer = new byte[(int) length];
                int read;
                if ((read = is.read(buffer)) != -1) {
//                    Log.d(TAG,"Data put into buffer: %d bytes", read);
                    inputBuffer.put(buffer, 0, read);

                    codec.queueInputBuffer(inputBufferId, 0, read, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM /*flags*/);
                    break;
                } else {
//                    Log.d(TAG,"Reached the end");
                    break;
                }
            }
        }

        is.close();

        Bitmap bitmap = null;
        MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();

        for (; ; ) {
            int decoderStatus = codec.dequeueOutputBuffer(info, timeoutUs);
            if (decoderStatus == MediaCodec.INFO_TRY_AGAIN_LATER) {
                // no output available yet
//                Log.d(TAG,"no output from decoder available");
//            } else if (decoderStatus == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED) {
//                // not important for us, since we're using SurfaceI
//                Log.d(TAG,"decoder output buffers changed");
            } else if (decoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                MediaFormat newFormat = codec.getOutputFormat();
//                Log.d(TAG,"decoder  output format changed: %s", newFormat);
//            } else if (decoderStatus == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED) {
//                Log.d(TAG,"output buffers changed");
            } else if (decoderStatus < 0) {
//                Timber.e("unknown decoder status: %d", decoderStatus);
//                fail("unexpected result from decoder.dequeueOutputBuffer: " + decoderStatus);
            } else { // decoderStatus >= 0
//                Log.d(TAG,"surface decoder given buffer " + decoderStatus +
//                        " (size=" + info.size + ")");

                boolean doRender = (info.size != 0);

                // As soon as we call releaseOutputBuffer, the buffer will be forwarded
                // to SurfaceTexture to convert to a texture.  The API doesn't guarantee
                // that the texture will be available before the call returns, so we
                // need to wait for the onFrameAvailable callback to fire.
                codec.releaseOutputBuffer(decoderStatus, doRender);
                if (doRender) {
//                    Log.d(TAG,"awaiting decode of frame ");
                    outputSurface.awaitNewImage();
                    outputSurface.drawImage();

                    bitmap = outputSurface.saveFrame();
                    break;
                }

                if ((info.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
//                    Log.d(TAG,"output EOS");
                    break;
                }

            }
        }

        outputSurface.release();

        codec.stop();
        codec.release();

        if (bitmap != null) {
            bitmap = Bitmap.createBitmap(bitmap, 0, 0, width, height);
        }

        return bitmap;
    }
}
