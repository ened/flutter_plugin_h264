package asia.ivity.h264example;

import android.os.Bundle;
import asia.ivity.h264.H264Plugin;
import dev.flutter.plugins.integration_test.IntegrationTestPlugin;
import io.flutter.app.FlutterActivity;

public class EmbeddingV1Activity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    H264Plugin.registerWith(registrarFor("asia.ivity.h264.H264Plugin"));
    IntegrationTestPlugin.registerWith(registrarFor("dev.flutter.plugins.integration_test"));
  }
}
