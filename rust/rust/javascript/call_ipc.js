
function sendIpc(msg) {

    var content = {
        type: "PostMessage",
        message: msg
    };

    window.ipc.postMessage(JSON.stringify({ "type": "Widget", "data": JSON.stringify(content) }));
}