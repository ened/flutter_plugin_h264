package asia.ivity.h264;

import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import asia.ivity.h264.util.H264Reader;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

/**
 * H264Plugin
 */
public class H264Plugin implements MethodCallHandler {

  private static final String TAG = "H264Plugin";
  private final Executor backgroundExecutor = Executors.newSingleThreadExecutor();

  private Handler mainThreadHandler;

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(),
        "asia.ivity.flutter/h264");
    channel.setMethodCallHandler(new H264Plugin());
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (mainThreadHandler == null) {
      mainThreadHandler = new Handler(Looper.getMainLooper());
    }

    if (call.method.equals("decode")) {
      backgroundExecutor.execute(() -> handleDecode(
          call.argument("source"),
          call.argument("width"),
          call.argument("height"),
          call.argument("target"),
          result,
          mainThreadHandler
      ));
    } else {
      result.notImplemented();
    }
  }

  private void handleDecode(String sourceFile, Integer width, Integer height, String targetFile,
      Result result, Handler resultHandler) {
    Log.d(TAG, "Starting a decoding process");
    try {
      final File source = new File(sourceFile);
      final FileInputStream fis = new FileInputStream(source);

      Bitmap decode = H264Reader.decode(fis, source.length(), width, height);

      if (decode != null) {
        final File target = new File(targetFile);
        FileOutputStream fos = new FileOutputStream(target);
        decode.compress(CompressFormat.JPEG, 80, fos);
        fos.close();

        resultHandler.post(() -> result.success(target.getAbsolutePath()));
      } else {
        throw new IOException("Can not decode the result");
      }
    } catch (Exception e) {
      resultHandler.post(() -> result.error("h264", e.getMessage(), null));
    }
  }
}
