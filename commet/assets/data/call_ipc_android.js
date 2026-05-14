var __internal_commet_widget_runner_msgCount = 0;

function sendIpc(msg) {
    __internal_commet_widget_runner_msgCount += 1;
    var key = "chat.commet.fromWidget:" + __internal_commet_widget_runner_msgCount.toString();

    // add '_' because somewhere it was getting auto-converted to json object
    sessionStorage.setItem(key, "_" + msg);
    window.flutter_inappwebview.callHandler("widget_handler", key)
}