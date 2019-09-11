// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:doc_checker/graph.dart';
import 'package:doc_checker/link_scraper.dart';
import 'package:doc_checker/projects.dart';

const String _optionHelp = 'help';
const String _optionRootDir = 'root-dir';
const String _optionDotFile = 'dot-file';
const String _optionGitProject = 'git-project';

void reportError(Error error) {
  String errorToString(ErrorType type) {
    switch (type) {
      case ErrorType.convertPathToHttp:
        return 'Convert path to http';
      case ErrorType.unknownLocalFile:
        return 'Linking to unknown file';
      case ErrorType.convertHttpToPath:
        return 'Convert http to path';
      case ErrorType.brokenLink:
        return 'Http link is broken';
      case ErrorType.unreachablePage:
        return 'Page should be reachable';
      case ErrorType.obsoleteProject:
        return 'Project is obsolete';
      case ErrorType.invalidUri:
        return 'Invalid URI';
      default:
        throw new UnsupportedError('Unknown error type $type');
    }
  }

  final String location = error.hasLocation ? ' (${error.location})' : '';
  print('${errorToString(error.type).padRight(25)}: ${error.content}$location');
}

enum ErrorType {
  convertPathToHttp,
  unknownLocalFile,
  convertHttpToPath,
  brokenLink,
  unreachablePage,
  obsoleteProject,
  invalidUri,
}

class Error {
  final ErrorType type;
  final String location;
  final String content;

  Error(this.type, this.location, this.content);

  Error.forProject(this.type, this.content) : location = null;

  bool get hasLocation => location != null;
}

Future<bool> isLinkValid(Uri link) async {
  try {
    return (await http.get(link)).statusCode == 200;
  } on IOException {
    return false;
  }
}

Future<Null> main(List<String> args) async {
  final ArgParser parser = new ArgParser()
    ..addFlag(
      _optionHelp,
      help: 'Displays this help message.',
      negatable: false,
    )
    ..addOption(
      _optionRootDir,
      help: 'Path to the directory to inspect',
      defaultsTo: 'docs',
    )
    ..addOption(
      _optionDotFile,
      help: 'Path to the dotfile to generate',
      defaultsTo: 'graph.dot',
    )
    ..addOption(
      _optionGitProject,
      help: 'Name of the Git project hosting the documentation directory',
      defaultsTo: 'docs',
    );
  final ArgResults options = parser.parse(args);

  if (options[_optionHelp]) {
    print(parser.usage);
    return;
  }

  final String docsDir = path.canonicalize(options[_optionRootDir]);

  final List<String> docs = new Directory(docsDir)
      .listSync(recursive: true)
      .where((FileSystemEntity entity) => path.extension(entity.path) == '.md')
      .map((FileSystemEntity entity) => entity.path)
      .toList();

  final String readme = path.join(docsDir, 'README.md');
  final Graph graph = new Graph();
  final List<Error> errors = <Error>[];
  final List<Future<Error>> pendingErrors = <Future<Error>>[];

  for (String doc in docs) {
    final String label = path.relative(doc, from: docsDir);
    final String baseDir = path.dirname(doc);
    final Node node = graph.getNode(label);
    if (doc == readme) {
      graph.root = node;
    }
    for (String link in new LinkScraper().scrape(doc)) {
      Uri uri;
      try {
        uri = Uri.parse(link);
      } on FormatException {
        errors.add(new Error(ErrorType.invalidUri, label, link));
        continue;
      }
      if (uri.hasScheme) {
        if (uri.scheme == 'http' || uri.scheme == 'https') {
          bool shouldTestLink = true;
          if (uri.authority == 'fuchsia.googlesource.com' &&
              uri.pathSegments.isNotEmpty) {
            if (uri.pathSegments[0] == options[_optionGitProject]) {
              shouldTestLink = false;
              errors.add(new Error(
                  ErrorType.convertHttpToPath, label, uri.toString()));
            } else if (!validProjects.contains(uri.pathSegments[0])) {
              shouldTestLink = false;
              errors.add(
                  new Error(ErrorType.obsoleteProject, label, uri.toString()));
            }
          }
          if (shouldTestLink) {
            pendingErrors.add(() async {
              if (!(await isLinkValid(uri))) {
                return new Error(ErrorType.brokenLink, label, uri.toString());
              }
              return null;
            }());
          }
        }
        continue;
      }
      final List<String> parts = link.split('#');
      final String location = parts[0];
      if (location.isEmpty) {
        continue;
      }
      final String absoluteLocation = path.canonicalize(location.startsWith('/')
          ? path.join(docsDir, location.substring(1))
          : path.join(baseDir, location));
      if (path.isWithin(docsDir, absoluteLocation)) {
        final String relativeLocation =
            path.relative(absoluteLocation, from: docsDir);
        if (docs.contains(absoluteLocation)) {
          graph.addEdge(from: node, to: graph.getNode(relativeLocation));
        } else {
          errors.add(
              new Error(ErrorType.unknownLocalFile, label, relativeLocation));
        }
      } else {
        errors.add(new Error(ErrorType.convertPathToHttp, label, location));
      }
    }
  }

  // Resolve all pending errors.
  errors.addAll(
      (await Future.wait(pendingErrors)).where((Error error) => error != null));

  // Verify singletons and orphans.
  final List<Node> unreachable = graph.removeSingletons()
    ..addAll(
        graph.orphans..removeWhere((Node node) => node.label == 'navbar.md'));
  for (Node node in unreachable) {
    errors.add(new Error.forProject(ErrorType.unreachablePage, node.label));
  }

  errors
    ..sort((Error a, Error b) => a.type.index - b.type.index)
    ..forEach(reportError);

  graph.export('fuchsia_docs', new File(options[_optionDotFile]).openWrite());

  if (errors.isNotEmpty) {
    print('Found ${errors.length} error(s).');
    exitCode = 1;
  }
}
