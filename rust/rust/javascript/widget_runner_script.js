(() => {

    function sendIpc(msg) {
        window.ipc.postMessage(JSON.stringify({ "type": "Widget", "data": JSON.stringify(msg) }));
    }

    function arrayBufferToBase64(buffer) {
        let binary = '';
        const bytes = new Uint8Array(buffer);
        const chunkSize = 0x8000;

        for (let i = 0; i < bytes.length; i += chunkSize) {
            binary += String.fromCharCode(...bytes.subarray(i, i + chunkSize));
        }

        return btoa(binary);
    }

    function base64ToArrayBuffer(base64) {
        const binary = atob(base64);
        const len = binary.length;
        const bytes = new Uint8Array(len);

        for (let i = 0; i < len; i++) {
            bytes[i] = binary.charCodeAt(i);
        }

        return bytes.buffer;
    }

    function encodeArrayBuffers(input) {
        if (input instanceof ArrayBuffer) {
            return {
                __type: "ArrayBuffer",
                data: arrayBufferToBase64(input),
            };
        }

        if (ArrayBuffer.isView(input)) {
            return {
                __type: "ArrayBuffer",
                data: arrayBufferToBase64(input.buffer),
            };
        }

        if (Array.isArray(input)) {
            return input.map(encodeArrayBuffers);
        }

        if (input !== null && typeof input === "object") {
            const result = {};
            for (const key in input) {
                result[key] = encodeArrayBuffers(input[key]);
            }
            return result;
        }

        return input;
    }


    function decodeArrayBuffers(input) {
        if (Array.isArray(input)) {
            return input.map(decodeArrayBuffers);
        }

        if (input !== null && typeof input === "object") {
            if (
                input.__type === "ArrayBuffer" &&
                typeof input.data === "string"
            ) {
                return base64ToArrayBuffer(input.data);
            }

            if (
                input.__type === "Blob" &&
                typeof input.data === "string"
            ) {
                var data = base64ToArrayBuffer(input.data);
                return new Blob([data]);
            }

            const result = {};
            for (const key in input) {
                result[key] = decodeArrayBuffers(input[key]);
            }
            return result;
        }

        return input;
    }

    window.parent.postMessage = (message, options) => {
        console.log("Posting message to parent: ", message, options);
        var msg = encodeArrayBuffers(message);
        var data = JSON.stringify(msg)

        sendIpc({
            type: "PostMessage",
            message: data,
        })

    }

    let original = window.addEventListener;

    let callbacks = new Array()

    window.addEventListener = (type, callback) => {
        if (type == "message") {
            callbacks.push(callback);
            console.log("Got callback for onMessage");
        } else {
            original(type, callback);
        }
    }


    window.onMessagePolyfill = (message) => {
        console.log("Received message from stdin!")
        console.log(message);

        var data = JSON.parse(message)
        data = decodeArrayBuffers(data)

        var event = {
            origin: "commet://widget",
            data: data
        }

        console.log("Dispatching message");

        if (window.onmessage != null) {
            window.onmessage(event);
        }

        callbacks.forEach((i) => { console.log(i); console.log(event); i(event) });
    }


    console.log("Started widget runner script");
})();