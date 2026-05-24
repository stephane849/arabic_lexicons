import 'dart:io';

import 'package:path/path.dart';

class Builder {
  String version;
  String gitCommit;
  String gitMessage;

  Builder({
    required this.version,
    required this.gitCommit,
    required this.gitMessage,
  });

  /// Creates a fully populated Builder
  static Future<Builder> create() async {
    final version = await _getVersion();
    var gitCommit = await _safeGit(["rev-parse", "HEAD"]);
    final gitMessage = await _safeGit(["log", "-1", "--pretty=%B"]);

    if (gitCommit.isNotEmpty) {
      gitCommit = gitCommit.substring(0, "46eff6d".length);
    }

    return Builder(
      version: version,
      gitCommit: gitCommit,
      gitMessage: gitMessage,
    );
  }

  static Future<String> _safeGit(
    List<String> args, {
    String defaultValue = "",
  }) async {
    try {
      final result = await Process.run("git", args);

      if (result.exitCode != 0) return defaultValue;

      return (result.stdout as String).trim();
    } catch (_) {
      return defaultValue;
    }
  }

  static Future<String> _getVersion() async {
    final file = File("pubspec.yaml");

    if (!await file.exists()) {
      stderr.writeln("No pubspec.yaml");
      exit(2);
    }

    final lines = await file.readAsLines();

    for (final line in lines) {
      if (line.startsWith("version:")) {
        return line.split("version:")[1].trim().split("+")[0];
      }
    }

    stderr.writeln("Could not get version info from pubspec.yaml");
    exit(3);
  }

  // equivalent of build_args()
  List<String> buildArgs() {
    return [
      "--dart-define=APP_VERSION=${version.isNotEmpty ? version : ''}",
      "--dart-define=BUILD_UNIX_TIME=${DateTime.now().millisecondsSinceEpoch ~/ 1000}",
      "--dart-define=GIT_COMMIT=$gitCommit",
      "--dart-define=GIT_COMMIT_MSG=$gitMessage",
    ];
  }

  // equivalent of run()
  Future<void> run(List<String> cmd) async {
    print("RUN: ${cmd.join(' ')}");

    final result = await Process.run(cmd.first, cmd.sublist(1));

    if (result.exitCode != 0) {
      throw ProcessException(
        cmd.first,
        cmd.sublist(1),
        result.stderr.toString(),
        result.exitCode,
      );
    }
  }
}

void main() async {
  final b = await Builder.create();

  final name = 'arabic_lexicons_v${b.version}_linux';

  final out = Directory("build-release").absolute;
  final zipOut = File(join(out.path, "$name.zip"));

  final base = Directory('build/linux/x64/release/').absolute;

  final bundle = Directory(join(base.path, 'bundle')).absolute;
  final lex = Directory(join(base.path, name)).absolute;

  await b.run(["flutter", "build", "linux", "--release", ...b.buildArgs()]);

  if (lex.existsSync()) lex.deleteSync(recursive: true);

  if (!out.existsSync()) out.createSync();

  bundle.renameSync(lex.path);

  File('assets/icons/icon.png').copySync(join(lex.path, 'icon.png'));
  File(
    'arabic_lexicons.desktop',
  ).copySync(join(lex.path, 'arabic_lexicons.desktop'));

  Directory.current = base;

  if (zipOut.existsSync()) zipOut.deleteSync();
  await b.run(["zip", "-r", zipOut.path, "arabic_lexicons"]);
}
