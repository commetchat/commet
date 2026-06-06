(() => {
    function sendIpc(msg) {
        window.ipc.postMessage(JSON.stringify({ "type": "WebRTC", "data": JSON.stringify(msg) }));

    }

    function uuid() {
        return crypto.randomUUID();
    }

    function unimplemented(message) {
        alert("Unimplemented: " + message);
    }

    const COMMET_WIDGET_RUNNER_DEBUG = true;
    const COMMET_WIDGET_RUNNER_ALERT_UNIMPLEMENTED = true;

    function dbg(args) {
        if (COMMET_WIDGET_RUNNER_DEBUG) {
            console.log(args)
        }
    }

    function createUnimplementedPropertyHandlers(object, propertyNames) {

        if (!COMMET_WIDGET_RUNNER_ALERT_UNIMPLEMENTED) return;

        propertyNames.forEach((property) => {
            var name = object.constructor.name + "." + property
            if (object.hasOwnProperty(property) == false) {
                dbg("Creating undefined property handler: ", name);

                Object.defineProperty(object, property, {
                    get() {
                        unimplemented(name)
                    }
                });
            } else {
                dbg("Property was defined: ", name);
            }
        });
    }

    function createUnimplementedFunctionHandlers(object, functionNames) {
        if (!COMMET_WIDGET_RUNNER_ALERT_UNIMPLEMENTED) return;

        functionNames.forEach((fn) => {
            var name = object.constructor.name + "." + fn + "();";
            if (typeof object[fn] != "function") {
                object[fn] = (args) => {
                    dbg("Creating unimplemented function handler: ", name);
                    unimplemented(object.constructor.name + "." + fn + "();")
                }
            } else {
                dbg("Function was implemented: ", name);
            }
        });
    }

    class RTCDataChannelPolyfill {
        constructor(peerConnectionID, label) {
            this.peerConnectionID = peerConnectionID;
            this.id = uuid();
            this.label = label;
            this.onopen = null;
            this.readyState = "connecting"
            this._eventManager = new EventTarget()

            console.log("Creating RTCDataChannel")

            sendIpc({
                type: "CreateDataChannel",
                pc_id: this.peerConnectionID,
                id: this.id,
                label: this.label
            })

            createUnimplementedPropertyHandlers(this, [
                "binaryType",
                "bufferedAmount",
                "bufferedAmountLowThreshold",
                "id",
                "label",
                "maxPacketLifeTime",
                "maxRetransmits",
                "negotiated",
                "ordered",
                "priority",
                "protocol",
                "readyState",
                "reliable",
            ]);

            createUnimplementedFunctionHandlers(this, [
                "close",
                "send",
            ]);
        }

        addEventListener(event, callback, options) {
            console.log("RTCDataChannel adding event listener: ", event);
            this._eventManager.addEventListener(event, callback, options);
        }

        removeEventListener(event, callback, options) {
            console.log("RTCDataChannel removing event listener: ", event);
            this._eventManager.removeEventListener(event, callback, options);
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

        _arrayBufferToHex(buffer) {
            return [...new Uint8Array(buffer)]
                .map(x => x.toString(16).padStart(2, '0'))
                .join('');
        }

        handleEvent(type, data) {

            if (type == "data_channel_opened") {
                this.readyState = "open";

                if (this.onopen != null) {
                    this.onopen();
                }

                this._eventManager.dispatchEvent(new Event("open"))
            } else if (type == "data_channel_on_message") {

                var msg = {};


                var event = new Event("message")

                if (data.type == "b64") {
                    var bytes = this._base64ToArrayBuffer(data.data)

                    event.data = bytes

                }

                if (data.type == "string") {
                    event.data = data.data
                }

                console.log(event);

                this.onmessage(msg)
                this._eventManager.dispatchEvent(event)
            } else {
                console.log("Unhandled data channel event: ", type, data)
            }
        }

        send(msg) {
            console.log("Sending data to channel: ", msg)

            if (typeof msg === 'string' || msg instanceof String) {
                sendIpc({
                    type: "SendData",
                    dc_id: this.id,
                    data: msg,
                    binary: false,
                })
            } else {
                sendIpc({
                    type: "SendData",
                    dc_id: this.id,
                    data: this._arrayBufferToBase64(msg),
                    binary: true,
                })
            }
        }
    }

    class RTCSessionDescriptionPolyfill {
        constructor(args) {
            console.log("Creating new rtc session description: ", args)

            this.sdp = args.sdp;
            this.type = args.type;

            createUnimplementedPropertyHandlers(this, [
                "sdp",
                "type"
            ]);

            createUnimplementedFunctionHandlers(this, [
                "toJSON"
            ]);
        }

        toJSON() {
            console.log("Converting Session Description to JSON");
            return {
                "sdp": this.sdp,
                "type": this.type,
            }
        }
    }

    class PolyfillRTCStatsReport {
        constructor(data) {
            this.data = data;

            createUnimplementedPropertyHandlers(this, [
                "size"
            ]);

            createUnimplementedFunctionHandlers(this, [
                "entries",
                "forEach",
                "get",
                "has",
                "keys",
                "values",
            ]);
        }

        get(key) {
            if (this.data.hasOwnProperty(key)) {
                return this.data[key];
            }
            return undefined;
        }

        keys() {
            return Object.keys(this.data)
        }

        values() {
            var v = Object.values(this.data);
            return v;
        }
    }

    class PolyfillRTCIceCandidate {
        constructor(args) {
            console.log("Constructing RTC ice candidate: ", args)
            this.candidate = args['candidate'];

            if (args.hasOwnProperty("usernameFragment")) {
                this.usernameFragment = args.usernameFragment;
            } else {
                this.usernameFragment = null;
            }


            if (args.hasOwnProperty("sdpMid")) {
                this.sdpMid = args.sdpMid;
            } else {
                this.sdpMid = "";
            }

            if (args.hasOwnProperty("sdpMLineIndex")) {
                this.sdpMLineIndex = 0; //args.sdpMLineIndex;
            } else {
                this.sdpMLineIndex = 0; //"";
            }

            console.log("Result: ", this);


            createUnimplementedPropertyHandlers(this, [
                "address",
                "candidate",
                "component",
                "foundation",
                "port",
                "priority",
                "protocol",
                "relatedAddress",
                "relatedPort",
                "sdpMid",
                "sdpMLineIndex",
                "tcpType",
                "type",
                "usernameFragment",
            ]);

            createUnimplementedFunctionHandlers(this, [
                "toJSON"
            ]);
        }

        toJSON() {
            return {
                "candidate": this.candidate,
                "sdpMid": this.sdpMid,
                "sdpMLineIndex": this.sdpMLineIndex,
                "usernameFragment": this.usernameFragment
            }
        }
    }

    class RTCPeerConnectionPolyfill {
        constructor(args) {

            console.log("Creating RTCPeerConnection")
            this.id = uuid();
            this.ondatachannel = null;
            this.onicecandidate = null;
            console.log(args);

            console.log("Creating Event Manager")
            this._eventManager = new EventTarget()
            this._dataChannels = new Map()

            this.connectionState = "new";
            this.iceGatheringState = "new";
            this.iceConnectionState = "new";
            this.localDescription = null;
            this.signalingState = "stable";

            console.log("Registering event handlers")

            this._eventCallbackId = window.toWebView.createEventHandler((value) => {
                var eventType = value.event_type;
                var eventData = value.event_data;

                console.log("RTCPeerConnection got event: ", eventType);
                console.log(eventData);

                if (eventType == "icecandidate") {


                    var ev = new Event("icecandidate", {});

                    if (eventData['candidate'] != null) {
                        ev.candidate = new PolyfillRTCIceCandidate(eventData['candidate']);
                    } else {
                        ev.candidate = null;
                    }

                    console.log("Dispatching event: ", ev);
                    if (this.onicecandidate != null) {
                        this.onicecandidate(ev)
                    }

                    this._eventManager.dispatchEvent(ev);
                }

                if (eventType == "negotiationneeded") {
                    console.log("Dispatching negotiation needed event");
                    this._eventManager.dispatchEvent(new Event("negotiationneeded"))
                }

                if (eventType == "signalingstatechange") {
                    var event = new Event("signalingstatechange")
                    event.signalingState = eventData['signalingState'];
                    this.signalingState = eventData['signalingState'];

                    this._eventManager.dispatchEvent(event);
                }

                if (eventType == "icegatheringstatechange") {
                    var event = new Event("icegatheringstatechange", eventData);
                    event.iceGatheringState = eventData['iceGatheringState'];
                    this.iceGatheringState = eventData['iceGatheringState'];

                    this._eventManager.dispatchEvent(event);
                }

                if (eventType == "iceconnectionstatechanged") {
                    var event = new Event("iceconnectionstatechanged")
                    event.iceConnectionState = eventData['iceConnectionState'];
                    this.iceConnectionState = eventData['iceConnectionState'];
                    this._eventManager.dispatchEvent(event);
                }

                if (eventType == "connectionstatechange") {
                    var event = new Event("connectionstatechange")
                    event.connectionState = eventData['connectionState'];
                    this.connectionState = eventData['connectionState'];
                    this._eventManager.dispatchEvent(event);
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
                ice_servers: args.iceServers,
            });


            createUnimplementedPropertyHandlers(this, [
                "localDescription",
                "canTrickleIceCandidates",
                "connectionState",
                "currentLocalDescription",
                "currentRemoteDescription",
                "iceConnectionState",
                "iceGatheringState",
                "idpLoginUrl",
                "localDescription",
                "peerIdentity",
                "pendingLocalDescription",
                "pendingRemoteDescription",
                "remoteDescription",
                "sctp",
                "signalingState",
            ]);

            createUnimplementedFunctionHandlers(this, [
                "addIceCandidate",
                "addStream",
                "addTrack",
                "addTransceiver",
                "close",
                "createAnswer",
                "createDataChannel",
                "createDTMFSender",
                "createOffer",
                "getConfiguration",
                "getIdentityAssertion",
                "getReceivers",
                "getSenders",
                "getStats",
                "removeStream",
                "removeTrack",
                "restartIce",
                "setConfiguration",
                "setIdentityProvider",
                "setLocalDescription",
                "setRemoteDescription",
            ]);
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

            console.log("Dispatching datachannel event");
            this._eventManager.dispatchEvent(new Event("datachannel", {
                "channel": channel
            }));

            return channel
        }

        addIceCandidate(candidate) {

            console.log("Adding ice candidate: ", candidate)

            if (candidate != null) {
                sendIpc({
                    type: "AddIceCandidate",
                    pc_id: this.id,
                    candidate: JSON.stringify(candidate.toJSON()),
                })
            } else {
                sendIpc({
                    type: "AddIceCandidate",
                    pc_id: this.id,
                })
            }
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

        async setLocalDescription(sessionDescription, successCallback, errorCallback) {
            console.log("Attempting to set local description!", sessionDescription, successCallback, errorCallback);

            let [id, promise] = window.toWebView.createPromise()


            if (sessionDescription != null) {
                sendIpc({
                    type: "SetLocalDescription",
                    promise_id: id,
                    pc_id: this.id,
                    sdp: sessionDescription.sdp,
                });
            } else {
                sendIpc({
                    type: "SetLocalDescription",
                    promise_id: id,
                    pc_id: this.id,
                });
            }

            let result = await promise;

            console.log("Got result from setLocalDescription!");
            console.log(result);


            this.localDescription = new RTCSessionDescriptionPolyfill(result);
        }

        setRemoteDescription(sdp) {
            let [id, promise] = window.toWebView.createPromise()


            console.log("TODO: Implement setRemoteDescription")
            console.log(sdp);

            sendIpc({
                type: "SetRemoteDescription",
                pc_id: this.id,
                sdp: sdp.sdp,
                sdp_type: sdp.type
            })

            return promise
        }

        async createAnswer(options) {

            console.log("Attempting to create webrtc answer: ", options)

            let [id, promise] = window.toWebView.createPromise()

            console.log("Promise: ", id, promise)

            sendIpc({
                type: "CreateAnswer",
                pc_id: this.id,
                promise_id: id,
            })

            var result = await promise;

            console.log("Received value: ", result);

            if (result.hasOwnProperty("error")) {
                throw new Error(result.error);
            }

            var returnValue = {
                type: "answer",
                sdp: result.sdp
            }

            console.log("Returning: ", returnValue);

            return returnValue
        }

        addEventListener(type, listener, options) {
            console.log("RTCPeerConnection adding event listener: ", type)
            this._eventManager.addEventListener(type, listener, options);
        }

        removeEventListener(type, listener, options) {
            console.log("RTCPeerConnection removing event listener: ", type)
            if (type == "icecandidate") {
                console.log("Removing ice candidate event listener");
            }
            this._eventManager.removeEventListener(type, listener, options);
        }

        async getStats(selector) {
            let [id, promise] = window.toWebView.createPromise()

            sendIpc({
                type: "GetStats",
                pc_id: this.id,
                promise_id: id,
            })

            var data = await promise;

            return new PolyfillRTCStatsReport(data)
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

    class RTCRtpSenderPolyfill {
        constructor() {

        }

        get prototype() {
            alert("RTCRtpSender is not supported on this platform");
        }
    }

    window.toWebView = new ToWebview()
    window.RTCPeerConnection = RTCPeerConnectionPolyfill;
    window.RTCSessionDescription = RTCSessionDescriptionPolyfill;
    window.RTCIceCandidate = PolyfillRTCIceCandidate;
    window.RTCRtpSender = new RTCRtpSenderPolyfill();
    window.RTCRtpScriptTransform = RTCRtpScriptTransformPolyfill
})();