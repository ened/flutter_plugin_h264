package asia.ivity.h264;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * H264Plugin
 */
public class H264Plugin implements FlutterPlugin {

  private MethodChannel channel;

  public static void registerWith(Registrar registrar) {
    H264Plugin instance = new H264Plugin();
    instance.startListening(registrar.messenger());
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    startListening(binding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    stopListening();
  }

  private void startListening(BinaryMessenger messenger) {
    channel = new MethodChannel(messenger, "asia.ivity.flutter/h264");
    channel.setMethodCallHandler(new MethodCallHandlerImpl());
  }

  private void stopListening() {
    channel.setMethodCallHandler(null);
  }
}
