// ignore_for_file: avoid_print

import 'dart:io';

getDependencies() async {
  var process = Process.runSync(
    "flutter",
    [
      "pub",
      "get",
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
}

intlUtilsGenerate() async {
  var process = await Process.run(
    "flutter",
    [
      "pub",
      "run",
      "intl_utils:generate",
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
}

Future<List<File>> generateFileLists() async {
  var dir = Directory("lib/generated/l10n");
  if (!dir.existsSync()) {
    dir.create(recursive: true);
  }

  var lib = Directory("lib");
  var files = lib.listSync(recursive: true);
  String fileList = "";

  //Write list of sources for l10n generation
  for (var file in files) {
    //skip generated files
    if (file.path.endsWith(".g.dart") ||
        file.path.contains("generated") ||
        file.path.contains("widgetbook")) {
      continue;
    }

    //skip non dart files
    if (!file.path.endsWith(".dart")) {
      continue;
    }

    fileList += "${file.absolute.path}\n";
  }

  var sourcesFile = File("lib/generated/l10n/sources_list_file.txt");

  await sourcesFile.create(recursive: true);
  sourcesFile.writeAsStringSync(fileList);

  lib = Directory("assets/l10n");
  files = lib.listSync(recursive: true);
  fileList = "";

  for (var file in files) {
    //skip non arb files
    if (!file.path.endsWith(".arb")) {
      continue;
    }

    fileList += "${file.absolute.path}\n";
  }

  var arbFile = File("lib/generated/l10n/arb_list_file.txt");

  await arbFile.create(recursive: true);
  arbFile.writeAsStringSync(fileList);

  return [sourcesFile, arbFile];
}

generateFromArb(List<File> files) async {
  var process = await Process.run(
    "flutter",
    [
      "pub",
      "run",
      "intl_translation:generate_from_arb",
      "--sources-list-file",
      files[0].absolute.path,
      "--translations-list-file",
      files[1].absolute.path,
      "--output-dir=lib/generated/l10n"
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
}

buildRunner() async {
  var process = await Process.run(
    "flutter",
    [
      "pub",
      "run",
      "build_runner",
      "build",
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
}

void main() async {
  await getDependencies();
  await intlUtilsGenerate();
  var files = await generateFileLists();
  await generateFromArb(files);
  await buildRunner();
}
