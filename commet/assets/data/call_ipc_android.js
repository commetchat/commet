
function sendIpc(msg) {
    window.flutter_inappwebview.callHandler("widget_handler", msg)
}