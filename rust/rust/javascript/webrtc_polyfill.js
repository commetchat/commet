(() => {
    function send(msg) {
        console.log("Sending message");
        console.log(msg);
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

            console.log("Creating RTCDataChannel")

            send({
                type: "CreateDataChannel",
                pc_id: this.peerConnectionID,
                id: this.id,
                label: this.label
            })
        }

        addEventListener(event, callback) {
            console.log("Adding event listener: ", event, callback);
        }

    }

    class RTCPeerConnectionPolyfill {
        constructor() {
            console.log("Creating RTCPeerConnection")
            this.id = uuid();
            this.ondatachannel = null;

            send({
                type: "CreatePeer",
                id: this.id
            });
        }

        close() {
            send({
                type: "ClosePeer",
                id: this.id
            });
        }

        ondatachannel = () => {

        }

        createDataChannel(label, dataChannelDict) {
            console.log("TODO: Implement create data channel: ", label, dataChannelDict);

            return new RTCDataChannelPolyfill(this.id, label)
        }

        createOffer(args) {
            console.log("Attempting to create webrtc offer: ", args)

            send({
                type: "CreateOffer",
                pc_id: this.id,
            })
        }

        setLocalDescription(sessionDescription, successCallback, errorCallback) {
            console.log("Attempting to set local description!", sessionDescription, successCallback, errorCallback);
        }

    }

    window.RTCPeerConnection = RTCPeerConnectionPolyfill;
})();