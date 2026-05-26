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

async function decodeArrayBuffers(input) {
    if (Array.isArray(input)) {
        return await Promise.all(
            input.map(async (element) => {
                return await decodeArrayBuffers(element)
            })
        );
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
            result[key] = await decodeArrayBuffers(input[key]);
        }
        return result;
    }

    return input;
}