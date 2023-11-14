package chat.commet.commetapp

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
}

abstract class BaseActivity : FlutterActivity() {

    abstract var entryPoint: String

    override fun getDartEntrypointFunctionName() = entryPoint

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) =
            GeneratedPluginRegistrant.registerWith(flutterEngine)
}

class BubbleActivity : BaseActivity() {
    override var entryPoint = "bubble"
}