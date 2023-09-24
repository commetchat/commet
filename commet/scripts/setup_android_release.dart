import 'dart:convert';
import 'dart:io';

String? getArg(List<String> args, String name) {
  int index = args.indexOf(name);
  if (index == -1) return null;

  return args[index + 1];
}

void writeEncodedKeyfile(String file) {
  var keyFile = File(file).readAsBytesSync();
  var b64 = base64.encode(keyFile);
  File("$file.b64").writeAsString(b64);
}

decodeAndWriteKeyFile(String keyB64) {
  var bytes = base64Decode(keyB64);
  var file = File("android/key.jks");
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }

  file.writeAsBytesSync(bytes);
}

writeKeyProperties(String password) {
  var file = File("android/key.properties");
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }

  file.writeAsStringSync("""
storePassword=$password
keyPassword=$password
keyAlias=key
storeFile=../key.jks
""");
}

main(List<String> args) {
  //Utility to encode a keyfile to base64, not needed for setup
  String? keyFile = getArg(args, "--key_file");

  if (keyFile != null) {
    writeEncodedKeyfile(keyFile);
    return;
  }

  String keyData = getArg(args, "--key_b64")!;
  String keyPassword = getArg(args, "--key_password")!;

  decodeAndWriteKeyFile(keyData);
  writeKeyProperties(keyPassword);
}
