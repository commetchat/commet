(() => {
    function sendIpc(msg) {
        window.ipc.postMessage(JSON.stringify(msg));
    }

    function uuid() {
        return crypto.randomUUID();
    }

    class RTCDataChannelPolyfill {
        constructor(peerConnectionID, label) {
            this.peerConnectionID = peerConnectionID;
            this.id = uuid();
            this.label = label;
            this.onopen = null;
            this.readyState = "connecting"
            this._eventManager = new PolyfillEventManager()

            console.log("Creating RTCDataChannel")

            sendIpc({
                type: "CreateDataChannel",
                pc_id: this.peerConnectionID,
                id: this.id,
                label: this.label
            })
        }

        addEventListener(event, callback) {
            this._eventManager.addListener(event, callback);
        }


        onopen = () => {

        }

        onmessage = (msg) => {

        }

        _base64ToArrayBuffer(base64) {
            var binaryString = atob(base64);
            var bytes = new Uint8Array(binaryString.length);
            for (var i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }
            return bytes.buffer;
        }

        _arrayBufferToBase64(buffer) {
            var binary = '';
            var bytes = new Uint8Array(buffer);
            var len = bytes.byteLength;
            for (var i = 0; i < len; i++) {
                binary += String.fromCharCode(bytes[i]);
            }
            return window.btoa(binary);
        }

        handleEvent(type, data) {

            if (type == "data_channel_opened") {
                this.readyState = "open";
                this.onopen();
                this._eventManager.invoke("open", null)
            } else if (type == "data_channel_on_message") {
                var msg = {
                    data: this._base64ToArrayBuffer(data.data)
                }

                console.log(msg);

                this.onmessage(msg)
                this._eventManager.invoke("message", msg)
            } else {
                console.log("Unhandled data channel event: ", type, data)
            }
        }

        send(msg) {
            // console.log("Sending data to channel: ", msg)

            sendIpc({
                type: "SendData",
                dc_id: this.id,
                data: this._arrayBufferToBase64(msg)
            })
        }
    }

    class RTCSessionDescriptionPolyfill {
        constructor(args) {
            console.log("Creating new rtc session description: ", args)

            this.sdp = args.sdp;
        }
    }

    class PolyfillEventManager {
        constructor() {
            console.log("Creating callbacks map")
            this.callbacks = new Map()
            console.log("Done!")
        }

        addListener(type, callback) {
            if (!this.callbacks.has(type)) {
                this.callbacks.set(type, new Array());
            }

            var list = this.callbacks.get(type);
            list.push(callback);
            this.callbacks.set(type, list);
        }

        invoke(type, value) {
            var list = this.callbacks.get(type);

            for (var i = 0; i < this.callbacks.length; i++) {
                var callback = this.callbacks[i];
                callback(value);
            }
        }
    }

    class RTCPeerConnectionPolyfill {
        constructor() {
            console.log("Creating RTCPeerConnection")
            this.id = uuid();
            this.ondatachannel = null;
            this.onicecandidate = null;

            console.log("Creating Event Manager")
            this._eventManager = new PolyfillEventManager()
            this._dataChannels = new Map()

            console.log("Registering event handlers")

            this._eventCallbackId = window.toWebView.createEventHandler((value) => {
                var eventType = value.event_type;
                var eventData = value.event_data;

                if (eventType == "onicecandidate") {
                    this.onicecandidate(eventData)
                    this._eventManager.invoke("onicecandidate", eventData);
                }

                if (eventType.startsWith("data_channel")) {
                    console.log(this._dataChannels);

                    var channel = this._dataChannels.get(eventData.channel);

                    console.log(channel);

                    channel.handleEvent(eventType, eventData)
                }

            });



            this._onEvent = window.toWebView.createEventHandler((value) => {
                console.log("Event :", value)
            });


            console.log("Sending CreatePeer")

            sendIpc({
                type: "CreatePeer",
                id: this.id,
                event_callback_id: this._eventCallbackId,
            });
        }

        close() {
            sendIpc({
                type: "ClosePeer",
                id: this.id
            });
        }

        ondatachannel = () => {

        }

        onicecandidate = () => {

        }

        createDataChannel(label, dataChannelDict) {
            var channel = new RTCDataChannelPolyfill(this.id, label)
            this._dataChannels.set(channel.id, channel);

            return channel
        }

        addIceCandidate(candidate) {
            sendIpc({
                type: "AddIceCandidate",
                pc_id: this.id,
                candidate: JSON.stringify(candidate),
            })
        }

        async createOffer(args) {
            console.log("Attempting to create webrtc offer: ", args)


            let [id, promise] = window.toWebView.createPromise()

            console.log("Promise: ", id, promise)

            sendIpc({
                type: "CreateOffer",
                pc_id: this.id,
                promise_id: id,
            })

            var result = await promise;

            console.log("Received value: ", result);

            var returnValue = {
                type: "offer",
                sdp: result.sdp
            }

            console.log("Returning: ", returnValue);

            return returnValue
        }

        setLocalDescription(sessionDescription, successCallback, errorCallback) {
            console.log("Attempting to set local description!", sessionDescription, successCallback, errorCallback);


            sendIpc({
                type: "SetLocalDescription",
                pc_id: this.id,
                sdp: sessionDescription.sdp,
            });

        }

        setRemoteDescription(sdp) {
            let [id, promise] = window.toWebView.createPromise()


            console.log("TODO: Implement setRemoteDescription")
            console.log(sdp);

            sendIpc({
                type: "SetRemoteDescription",
                pc_id: this.id,
                sdp: sdp.sdp,
            })

            return promise
        }

        createAnswer(options) {
            console.log("TODO: implement createAnswer:", options)
        }

        addEventListener(name, callback) {
            this._eventManager.addListener(name, callback);
        }

    }

    class ToWebview {
        constructor() {
            this.promises = new Map()
            this.eventHandlers = new Map()
        }

        randomString(length) {
            var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz'.split('');

            if (!length) {
                length = Math.floor(Math.random() * chars.length);
            }

            var str = '';
            for (var i = 0; i < length; i++) {
                str += chars[Math.floor(Math.random() * chars.length)];
            }
            return str;
        }

        uniquePromiseId() {
            while (true) {
                var id = this.randomString(32);

                if (!this.promises.has(id)) {
                    return id;
                }
            }
        }

        uniqueEventId() {
            while (true) {
                var id = this.randomString(32);

                if (!this.eventHandlers.has(id)) {
                    return id;
                }
            }
        }

        createPromise() {
            var id = this.uniquePromiseId();

            var p = new Promise((resolve, reject) => {
                this.promises.set(id, [resolve, reject]);
            });

            return [id, p];
        }

        resolvePromise(id, result) {
            console.log("Attempting to resolve promise: ", id, result);

            var callbacks = this.promises.get(id);
            var resolve = callbacks[0];


            resolve(result)
        }

        createEventHandler(callback) {
            var id = this.uniqueEventId();
            this.eventHandlers.set(id, callback);

            return id;
        }

        invokeEvent(callback_id, value) {
            console.log("Attempting to invoke event handler: ", callback_id, value);

            var callback = this.eventHandlers.get(callback_id);
            callback(value);
        }
    }

    window.toWebView = new ToWebview()
    window.RTCPeerConnection = RTCPeerConnectionPolyfill;
    window.RTCSessionDescription = RTCSessionDescriptionPolyfill;
})();