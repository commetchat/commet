import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

bool isE2EESupported() {
  return isInsertableStreamSupported() || isScriptTransformSupported();
}

bool isScriptTransformSupported() {
  return web.window.hasProperty('RTCRtpScriptTransform'.toJS).toDart;
}

bool isInsertableStreamSupported() {
  return web.window.hasProperty('RTCRtpSender'.toJS).toDart &&
      web.window.getProperty<web.RTCRtpSender>('RTCRtpSender'.toJS).hasProperty('createEncodedStreams'.toJS).toDart;
}

Future<web.CryptoKey> createKeyMaterialFromString(Uint8List keyBytes, String algorithm, String usage) {
  // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey
  return web.window.crypto.subtle
      .importKey(
        'raw',
        keyBytes.toJS,
        {'name': 'PBKDF2'}.jsify() as web.AlgorithmIdentifier,
        false,
        ['deriveBits', 'deriveKey'].jsify() as JSArray<JSString>,
      )
      .toDart;
}

Map<String, dynamic> getAlgoOptions(String algorithmName, Uint8List salt) {
  switch (algorithmName) {
    case 'HKDF':
      return {
        'name': 'HKDF',
        'salt': salt,
        'hash': 'SHA-256',
        'info': Uint8List(128),
      };
    case 'PBKDF2':
      {
        return {
          'name': 'PBKDF2',
          'salt': salt,
          'hash': 'SHA-256',
          'iterations': 100000,
        };
      }
    default:
      throw Exception('algorithm $algorithmName is currently unsupported');
  }
}

bool needsRbspUnescaping(Uint8List frameData) {
  for (var i = 0; i < frameData.length - 3; i++) {
    if (frameData[i] == 0 && frameData[i + 1] == 0 && frameData[i + 2] == 3) {
      return true;
    }
  }
  return false;
}

Uint8List parseRbsp(Uint8List stream) {
  final List<int> dataOut = [];
  final length = stream.length;
  for (var i = 0; i < stream.length;) {
    // Be careful about over/underflow here. byte_length_ - 3 can underflow, and
    // i + 3 can overflow, but byte_length_ - i can't, because i < byte_length_
    // above, and that expression will produce the number of bytes left in
    // the stream including the byte at i.
    if (length - i >= 3 && stream[i] == 0 && stream[i + 1] == 0 && stream[i + 2] == 3) {
      // Two rbsp bytes.
      dataOut.add(stream[i++]);
      dataOut.add(stream[i++]);
      // Skip the emulation byte.
      i++;
    } else {
      // Single rbsp byte.
      dataOut.add(stream[i++]);
    }
  }
  return Uint8List.fromList(dataOut);
}

const kZerosInStartSequence = 2;
const kEmulationByte = 3;

Uint8List writeRbsp(Uint8List dataIn) {
  final List<int> dataOut = [];
  var numConsecutiveZeros = 0;
  for (var i = 0; i < dataIn.length; ++i) {
    final byte = dataIn[i];
    if (byte <= kEmulationByte && numConsecutiveZeros >= kZerosInStartSequence) {
      // Need to escape.
      dataOut.add(kEmulationByte);
      numConsecutiveZeros = 0;
    }
    dataOut.add(byte);
    if (byte == 0) {
      ++numConsecutiveZeros;
    } else {
      numConsecutiveZeros = 0;
    }
  }
  return Uint8List.fromList(dataOut);
}
