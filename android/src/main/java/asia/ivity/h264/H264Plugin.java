package asia.ivity.h264;

import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
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
import java.util.Map;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

/**
 * H264Plugin
 */
public class H264Plugin implements MethodCallHandler {

  private static final String TAG = "H264Plugin";
  private final Executor backgroundExecutor = Executors.newSingleThreadExecutor();

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
    if (call.method.equals("decode")) {
      final Map<String, Object> params = (Map<String, Object>) call.arguments;

      backgroundExecutor.execute(() -> handleDecode(params, result));
    } else {
      result.notImplemented();
    }
  }

  private void handleDecode(Map<String, Object> params, Result result) {
    Log.d(TAG, "Starting a decoding process");
    try {
      final File source = new File((String) params.get("source"));
      final FileInputStream fis = new FileInputStream(source);

      Bitmap decode = H264Reader.decode(fis, source.length(), (Integer) params.get("width"),
          (Integer) params.get("height"));

      if (decode != null) {
        final File target = new File((String) params.get("target"));
        decode.compress(CompressFormat.JPEG, 80, new FileOutputStream(target));
        result.success(target.getAbsolutePath());
      } else {
        result.error("h264", "", null);
      }
    } catch (Exception e) {
      result.error("h264", "", e);
    }
  }
}
