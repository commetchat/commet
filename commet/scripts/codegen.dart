// ignore_for_file: avoid_print

import 'dart:io';

Future<ProcessResult> getDependencies() async {
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
  return process;
}

Future<ProcessResult> intlUtilsGenerate() async {
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
  return process;
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

Future<ProcessResult> generateFromArb(List<File> files) async {
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
  return process;
}

Future<ProcessResult> buildRunner() async {
  var process = await Process.run(
    "flutter",
    [
      "pub",
      "run",
      "build_runner",
      "build",
      "--delete-conflicting-outputs",
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
  return process;
}

void main() async {
  var result = await getDependencies();
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }

  result = await intlUtilsGenerate();
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }

  var files = await generateFileLists();
  result = await generateFromArb(files);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }

  result = await buildRunner();
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}
