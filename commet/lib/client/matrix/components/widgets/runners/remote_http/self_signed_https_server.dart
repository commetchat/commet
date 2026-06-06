import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/services.dart';

class CertificateData {
  final Uint8List certBytes;
  final Uint8List privateKeyBytes;

  CertificateData({
    required this.certBytes,
    required this.privateKeyBytes,
  });
}

Future<HttpServer> spawnSelfSignedHttpsServer(String hostname) async {
  final certData = await generateSelfSignedCertificate(hostname);

  final context = SecurityContext()
    ..useCertificateChainBytes(certData.certBytes)
    ..usePrivateKeyBytes(certData.privateKeyBytes);

  var server =
      await HttpServer.bindSecure(InternetAddress.anyIPv4, 4185, context);

  return server;
}

Future<CertificateData> generateSelfSignedCertificate(String host) async {
  final pair = CryptoUtils.generateRSAKeyPair();

  final privateKey = pair.privateKey as RSAPrivateKey;
  final publicKey = pair.publicKey as RSAPublicKey;

  final csr = X509Utils.generateRsaCsrPem(
    {
      'CN': host,
    },
    privateKey,
    publicKey,
  );

  final certPem = X509Utils.generateSelfSignedCertificate(
    privateKey,
    csr,
    365,
    sans: [host],
  );
  final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);

  return CertificateData(
    certBytes: Uint8List.fromList(
      utf8.encode(certPem),
    ),
    privateKeyBytes: Uint8List.fromList(
      utf8.encode(privateKeyPem),
    ),
  );
}
