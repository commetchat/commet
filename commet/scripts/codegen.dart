// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

Future<int> run(String command, List<String> args) async {
  var process = await Process.start(command, args, runInShell: true);

  process.stdout.transform(utf8.decoder).listen((i) => print(i));
  process.stderr.transform(utf8.decoder).listen((i) => print(i));

  return await process.exitCode;
}

Future<int> getDependencies() async {
  return await run("flutter", [
    "pub",
    "get",
  ]);
}

Future<int> intlUtilsGenerate() async {
  return await run(
    "flutter",
    [
      "pub",
      "run",
      "intl_utils:generate",
    ],
  );
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

Future<int> generateFromArb(List<File> files) async {
  return await run("flutter", [
    "pub",
    "run",
    "intl_translation:generate_from_arb",
    "--sources-list-file",
    files[0].absolute.path,
    "--translations-list-file",
    files[1].absolute.path,
    "--output-dir=lib/generated/l10n"
  ]);
}

Future<int> buildRunner() async {
  return await run("flutter", [
    "pub",
    "run",
    "build_runner",
    "build",
    "--delete-conflicting-outputs",
  ]);
}

void main() async {
  print("---- Getting Dependencies ----");
  var result = await getDependencies();
  if (result != 0) {
    exit(result);
  }

  print("---- Finished Getting Dependencies! ----");

  print("---- Generating Translation Code ----");
  result = await intlUtilsGenerate();
  if (result != 0) {
    exit(result);
  }

  print("---- Finished Generating Translation Code! ----");

  print("---- Generating File Lists ----");
  var files = await generateFileLists();
  result = await generateFromArb(files);
  if (result != 0) {
    exit(result);
  }

  print("---- Finished Generating File Lists! ----");

  print("---- Running Build Runner ----");

  result = await buildRunner();
  if (result != 0) {
    exit(result);
  }
}
