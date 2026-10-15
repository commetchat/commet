(() => {

    //${SEND_IPC_CODE}

    //${WIDGETS_COMMON}

    window.parent.postMessage = (message, options) => {
        var msg = encodeArrayBuffers(message);
        var data = JSON.stringify(msg)

        sendIpc(data)

    }

    let original = window.addEventListener;

    let callbacks = new Array()

    window.addEventListener = (type, callback) => {
        if (type == "message") {
            callbacks.push(callback);

        } else {
            original(type, callback);
        }
    }


    window.onMessagePolyfill = (message) => {
        var data = JSON.parse(message)
        decodeArrayBuffers(data).then((value) => {

            var event = {
                origin: "commet://widget",
                data: value
            }

            if (window.onmessage != null) {
                window.onmessage(event);
            }

            callbacks.forEach((i) => { i(event) });
        });
    }


    console.log("Started widget runner script");
})();