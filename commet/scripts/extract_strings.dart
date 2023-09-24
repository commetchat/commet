// ignore_for_file: avoid_print

import 'dart:io';

import './codegen.dart' as codegen;

void extractStrings(List<File> files) async {
  var process = await Process.run(
    "flutter",
    [
      "pub",
      "run",
      "intl_translation:extract_to_arb",
      "--sources-list-file",
      files[0].absolute.path,
      "--output-dir=./assets/l10n/",
      "--output-file=intl_en.arb"
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
}

main() async {
  var files = await codegen.generateFileLists();
  extractStrings(files);
}
