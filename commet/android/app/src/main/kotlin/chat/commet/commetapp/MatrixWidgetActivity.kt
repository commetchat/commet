package chat.commet.commetapp

import android.annotation.SuppressLint
import android.app.Activity
import android.net.LocalSocket
import android.net.LocalSocketAddress
import android.os.Bundle
import android.util.DisplayMetrics
import android.util.Log
import android.view.View
import android.view.View.OVER_SCROLL_NEVER
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.doOnAttach
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext


private const val TAG = "WidgetActivity"


private fun Int.toDp(density: Density): Dp = with(density) { this@toDp.toDp() }

class WidgetWebViewClient : WebViewClient {
    constructor(view: android.view.View, webView: WebView, density: Density) {
        ViewCompat.setOnApplyWindowInsetsListener(view) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())

            applySafeAreaInsetsToWebView(systemBars, webView, density)

            val edgeToEdge = true;
            if(edgeToEdge) {
               v.setPadding(0, 0, 0, 0);
            } else {
                v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            }
            insets
        }
    }

    private fun applySafeAreaInsetsToWebView(
        insets: Insets,
        webView: WebView?,
        density: Density){
        // Convert raw pixels to density independent pixels
        val top = insets.top.toDp(density);
        val right = insets.right.toDp(density);
        val bottom = insets.bottom.toDp(density);
        val left = insets.left.toDp(density);

        val safeAreaJs = """
            document.documentElement.style.setProperty('--safe-area-inset-top', '${top.value}px');
            document.documentElement.style.setProperty('--safe-area-inset-right', '${right.value}px');
            document.documentElement.style.setProperty('--safe-area-inset-bottom', '${bottom.value}px');
            document.documentElement.style.setProperty('--safe-area-inset-left', '${left.value}px');
            window.updateSafeAreas();
            """

        Log.d(TAG, "Injecting safe area variables!" + safeAreaJs)

        webView!!.setPadding(insets.left, insets.top, insets.right, insets.bottom)
        // Inject the density independent pixels into the CSS variables as CSS pixels
        webView.evaluateJavascript(safeAreaJs, null)
    }


}

class MatrixWidgetActivity : AppCompatActivity() {
    private var socket: LocalSocket? = null;

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val intent = getIntent()

        val socketPath = intent.getStringExtra("socket");
        var page = intent.getStringExtra("page");

        setContentView(R.layout.activity_matrix_widget)

        if(page == null) {
            val webView: WebView = findViewById(R.id.webview);
            val view = findViewById<View>(R.id.main);
            webView.loadUrl("https://commet.chat/")
            return;
        };

        Log.d(TAG, "Socket: $socket");

        val rootView = findViewById<View>(R.id.main);

        rootView.doOnAttach {
            val rootInsets = ViewCompat.getRootWindowInsets(rootView)

            val insets =
                rootInsets?.getInsets(WindowInsetsCompat.Type.systemBars())


            val density = Density(this)

            if(insets != null) {
                val top = insets.top.toDp(density);
                val right = insets.right.toDp(density);
                val bottom = insets.bottom.toDp(density);
                val left = insets.left.toDp(density);

                val safeAreaStr = "${left.value}px,${top.value}px,${right.value}px,${bottom.value}px";
                page = page!!.replace("%24chat.commet.safe_area", safeAreaStr);

                Log.i(TAG, "Added safe area to page");
            } else {
                Log.e(TAG, "Failed to get initial widget insets");
            }

            val webView: WebView = initWebView(page, insets);

            val newSocket = LocalSocket();
            newSocket.connect(LocalSocketAddress(socketPath, LocalSocketAddress.Namespace.FILESYSTEM));

            socket = newSocket;
            readDataLoop(newSocket, webView, this);
        }
        WindowCompat.setDecorFitsSystemWindows(window, true)
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun initWebView(page: String?, insets: Insets?): WebView {
        val webView: WebView = findViewById(R.id.webview);
        val view = findViewById<View>(R.id.main);
        val density = Density(this)
        webView.webViewClient = WidgetWebViewClient(view, webView, density);

        webView.settings.javaScriptEnabled = true;
        webView.settings.domStorageEnabled = true;

        webView.loadDataWithBaseURL("http://localhost/widget", page!!, "text/html", "UTF-8", null);
        webView.addJavascriptInterface(this, "WidgetRunner");
        webView.overScrollMode = OVER_SCROLL_NEVER;
        return webView
    }

    fun readDataLoop(socket: LocalSocket, webView: WebView, activity: Activity) {
        CoroutineScope(Dispatchers.IO).launch {

            val lineBuffer = StringBuilder()
            val readBuffer = ByteArray(100_000)

            while (socket.isConnected) {

                val read = socket.inputStream.read(readBuffer)
                if (read == -1) {
                    Log.d(TAG, "Socket Closed!!!");
                    withContext(Dispatchers.Main) {
                        activity.finishAndRemoveTask();
                    }
                    return@launch;
                }
                val dataStr = String(readBuffer, 0, read, Charsets.UTF_8)

                lineBuffer.append(dataStr)
                var idx = lineBuffer.indexOf("\n")

                while (idx >= 0) {

                    val line = lineBuffer.substring(0, idx)
                    lineBuffer.delete(0, idx + 1)
                    idx = lineBuffer.indexOf("\n")


                    var debugStr = line;
                    if(line.length > 500) {
                        debugStr = line.substring(0,  500);
                    }
                    Log.d(TAG, "Received message: " + debugStr);

                    val b64 = android.util.Base64.encodeToString(
                        line.toByteArray(),
                        android.util.Base64.NO_WRAP
                    )
                    withContext(Dispatchers.Main) {
                        webView.evaluateJavascript("window.onMessagePolyfill(\"$b64\")") {
                        }
                    }
                }
            }
        }
    }

    @JavascriptInterface
    fun send(data: String) {
        val writer = socket!!.outputStream.bufferedWriter();

        writer.write(data);
        writer.newLine();
        writer.flush();
    }
}