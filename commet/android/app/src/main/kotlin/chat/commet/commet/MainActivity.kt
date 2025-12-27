package chat.commet.commetapp

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.inputmethod.InputMethodManager
import androidx.annotation.NonNull
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity: FlutterActivity() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return provideEngine(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        registerMethods(flutterEngine, this);
    }

    companion object {
        var engine: FlutterEngine? = null
        fun provideEngine(context: Context): FlutterEngine {
            val eng = engine ?: FlutterEngine(context, emptyArray(), true, false)
            engine = eng
            return eng
        }
    }
}

abstract class BaseActivity : FlutterActivity() {

    abstract var entryPoint: String

    override fun getDartEntrypointFunctionName() = entryPoint

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        registerMethods(flutterEngine, this);
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}

class BubbleActivity : BaseActivity() {
    override var entryPoint = "bubble"
}

fun registerMethods(flutterEngine: FlutterEngine, activity: Activity) {
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "chat.commet.commetapp/utils").apply {
        setMethodCallHandler { call, result ->
            if(call.method == "dismissKeyboard") {
                hideKeyboard(activity);
                result.success(null);
            }
            if(call.method == "isKeyboardOpen") {
                result.success(isKeyboardOpen(activity));
            }
        }
    }
}

fun hideKeyboard(activity: Activity) {
    val imm = activity.getSystemService(Activity.INPUT_METHOD_SERVICE) as InputMethodManager
    //Find the currently focused view, so we can grab the correct window token from it.
    var view = activity.getCurrentFocus()
    //If no view currently has focus, create a new one, just so we can grab a window token from it
    if (view == null) {
        view = View(activity)
    }
    imm.hideSoftInputFromWindow(view.getWindowToken(), 0)
}

fun isKeyboardOpen(activity: Activity): Boolean {
    val insets = ViewCompat.getRootWindowInsets(activity.window.decorView.rootView)
    return insets?.isVisible(WindowInsetsCompat.Type.ime()) == true
}