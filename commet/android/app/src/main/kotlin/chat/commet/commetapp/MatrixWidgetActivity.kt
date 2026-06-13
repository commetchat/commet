package chat.commet.commetapp

import android.annotation.SuppressLint
import android.app.Activity
import android.net.LocalSocket
import android.net.LocalSocketAddress
import android.os.Bundle
import android.util.Log
import android.view.View.OVER_SCROLL_NEVER
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext


private const val TAG = "WidgetActivity"

class WidgetWebViewClient : WebViewClient() {

}

class MatrixWidgetActivity : AppCompatActivity() {
    private var socket: LocalSocket? = null;

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val intent = getIntent()
        val url = intent.getStringExtra("url");
        val socketPath = intent.getStringExtra("socket");
        val page = intent.getStringExtra("page");
        Log.d(TAG, "URL: $url");
        Log.d(TAG, "Socket: $socket");

        setContentView(R.layout.activity_matrix_widget)
        val webView: WebView = initWebView(page)

        val newSocket = LocalSocket();
        newSocket.connect(LocalSocketAddress(socketPath, LocalSocketAddress.Namespace.FILESYSTEM));

        socket = newSocket;

        readDataLoop(newSocket, webView, this);

        WindowCompat.setDecorFitsSystemWindows(window, true)

        val edgeToEdge = true;

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            if(edgeToEdge) {
                v.setPadding(0, 0, 0, 0);
            } else {
                v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            }
            insets
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun initWebView(page: String?): WebView {
        val webView: WebView = findViewById(R.id.webview);
        webView.webViewClient = WidgetWebViewClient();

        webView.settings.javaScriptEnabled = true;
        webView.settings.domStorageEnabled = true;
        webView.setPadding(0, 0, 0, 0)
        webView.clipToPadding = false
        webView.loadDataWithBaseURL("http://localhost/widget", page!!, "text/html", "UTF-8", null);
        webView.addJavascriptInterface(this, "WidgetRunner");
        webView.overScrollMode = OVER_SCROLL_NEVER;
        return webView
    }

    fun readDataLoop(socket: LocalSocket, webView: WebView, activity: Activity) {
        CoroutineScope(Dispatchers.IO).launch {

            val lineBuffer = StringBuilder()
            val readBuffer = ByteArray(8096)

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