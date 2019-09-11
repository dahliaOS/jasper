// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:collection';
import 'dart:io' as io;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:glob/glob.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart' as pkgfile;
import 'package:package_config/src/packages_impl.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';
import 'widget_specs.dart';

/// Extracts all the flutter widgets and their specs from the given package.
///
/// The dart files are assumed to be under the `lib` directory.
List<WidgetSpecs> extractWidgetSpecs(String packagePath, {String fuchsiaRoot}) {
  // Initialize the analysis engine.
  AnalysisContext context = _initContext(packagePath);
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  // Enumerate all the source files that need to be analyzed.
  List<Source> sources = <Source>[];
  ChangeSet cs = new ChangeSet();

  Glob pattern = new Glob('$packagePath/lib/**.dart');
  String libDir = path.join(packagePath, 'lib');
  String libSrcDir = path.join(libDir, 'src');

  for (io.FileSystemEntity file in pattern.listSync()) {
    if (file.path.startsWith(libSrcDir)) {
      continue;
    }

    File sourceFile = resourceProvider.getFile(file.absolute.path);
    Source source = sourceFile.createSource();
    Uri uri = context.sourceFactory.restoreUri(source);
    if (uri != null) {
      source = sourceFile.createSource(uri);
    }
    sources.add(source);
    cs.addedSource(source);
  }

  // Add all the source files to the analysis context.
  context.applyChanges(cs);

  Set<LibraryElement> libraries = new Set<LibraryElement>();

  return sources
      .expand((Source source) => _extractWidgetSpecsFromSource(
          context, source, libraries, fuchsiaRoot))
      .toList()
        ..sort();
}

List<WidgetSpecs> _extractWidgetSpecsFromSource(
  AnalysisContext context,
  Source source,
  Set<LibraryElement> libraries,
  String fuchsiaRoot,
) {
  Queue<LibraryElement> queue = new Queue<LibraryElement>();
  Set<LibraryElement> newLibraries = new Set<LibraryElement>();

  LibraryElement libElement = context.computeLibraryElement(source);
  queue.add(libElement);

  while (queue.isNotEmpty) {
    LibraryElement libElement = queue.removeFirst();
    // Avoid processing the same library more than once.
    if (libraries.contains(libElement)) {
      continue;
    }

    queue.addAll(libElement.exportedLibraries);
    libraries.add(libElement);
    newLibraries.add(libElement);
  }

  // From the libraries extracted from the current source, extract all the
  // public flutter widget classes.
  List<ClassElement> types = newLibraries
      .expand((LibraryElement lib) => lib.units)
      .expand((CompilationUnitElement cu) => cu.types)
      .where(_isPublicFlutterWidget)
      .toList();

  // Create widget specs from the given types.
  return types
      .map(new _WidgetSpecsCreator(source, context, fuchsiaRoot))
      .toList();
}

/// Initialize the [AnalysisContext] in which the analysis will be performed.
AnalysisContext _initContext(String packagePath) {
  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();

  io.File packagesFile = new io.File(path.join(packagePath, '.packages'));
  if (!packagesFile.existsSync()) {
    throw new Exception('.packages file is not found in "$packagePath". '
        'Please run "flutter packages get" from the package directory.');
  }

  Map<String, Uri> map = pkgfile.parse(
    packagesFile.readAsBytesSync(),
    packagesFile.uri,
  );
  Packages packages = new MapPackages(map);

  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  String sdkDir;
  if (io.Platform.executable == null) {
    // See if the resolved executable is the sky_shell.
    // (when running under the flutter test environment)
    if (path.basename(io.Platform.resolvedExecutable) == 'sky_shell') {
      io.Directory cacheDir = new io.File(io.Platform.resolvedExecutable)
          ?.parent
          ?.parent
          ?.parent
          ?.parent;
      if (cacheDir != null && path.basename(cacheDir.path) == 'cache') {
        sdkDir = path.join(cacheDir.path, 'dart-sdk');
      }
    }
  } else {
    sdkDir = cli_util.getSdkPath();
  }

  // Try locating an Embedder SDK.
  EmbedderYamlLocator locator = new EmbedderYamlLocator(
    _convertPackagesToMap(resourceProvider, packages),
  );
  DartSdk sdk;

  if (locator.embedderYamls.isNotEmpty) {
    // Create and configure an embedded SDK.
    sdk = new EmbedderSdk(
        PhysicalResourceProvider.INSTANCE, locator.embedderYamls);
  } else {
    sdk = new FolderBasedDartSdk(
      resourceProvider,
      resourceProvider.getFolder(sdkDir),
    );
  }

  List<UriResolver> resolvers = <UriResolver>[
    new DartUriResolver(sdk),
    new ResourceUriResolver(resourceProvider),
  ];

  context.sourceFactory = new SourceFactory(resolvers, packages);

  return context;
}

Map<String, List<Folder>> _convertPackagesToMap(
  ResourceProvider resourceProvider,
  Packages packages,
) {
  if (packages == null || packages == Packages.noPackages) {
    return null;
  }
  Map<String, List<Folder>> folderMap = new HashMap<String, List<Folder>>();
  packages.asMap().forEach((String packagePath, Uri uri) {
    String path = resourceProvider.pathContext.fromUri(uri);
    folderMap[packagePath] = <Folder>[resourceProvider.getFolder(path)];
  });
  return folderMap;
}

/// A helper class for creating [WidgetSpecs] from [ClassDeclaration]s.
class _WidgetSpecsCreator {
  _WidgetSpecsCreator(this.source, this.context, this.fuchsiaRoot);

  final Source source;

  final AnalysisContext context;

  final String fuchsiaRoot;

  /// Creates a new [WidgetSpecs] instance from the given [ClassDeclaration].
  ///
  /// The given [ClassDeclaration] should be a flutter widget class inheriting
  /// either `StatelessWidget` or `StatefulWidget`.
  WidgetSpecs call(ClassElement c) {
    if (c == null) {
      return null;
    }

    String name = c.name;
    String doc;

    // See if there is a documentation comment associated with this class.
    if (c.documentationComment != null) {
      doc = _trimCommentPrefixes(c.documentationComment);
    }

    // Calculate the path from fuchsia root, if the fuchsia root path is given.
    String pathFromFuchsiaRoot;
    if (fuchsiaRoot != null) {
      String absSourcePath = c.librarySource.fullName;
      String absFuchsiaRoot = path.absolute(fuchsiaRoot);
      pathFromFuchsiaRoot = path.relative(absSourcePath, from: absFuchsiaRoot);
    }

    // Fill in the example size information.
    double exampleWidth, exampleHeight;
    DartObject exampleSizeObject =
        getAnnotationWithName(c, 'ExampleSize')?.computeConstantValue();
    if (exampleSizeObject != null) {
      exampleWidth = exampleSizeObject.getField('width')?.toDoubleValue();
      exampleHeight = exampleSizeObject.getField('height')?.toDoubleValue();
    }

    // Fill in the hasSizeParam information.
    bool hasSizeParam;
    ConstructorElement constructor = c.constructors.firstWhere(
      (ConstructorElement constructor) => constructor.isDefaultConstructor,
      orElse: () => null,
    );
    hasSizeParam = constructor?.parameters?.any((ParameterElement param) =>
            getAnnotationWithName(param, '_SizeParam') != null) ??
        false;

    return new WidgetSpecs(
      packageName: source.uri.pathSegments[0],
      name: name,
      path: source.uri.pathSegments.skip(1).join('/'),
      pathFromFuchsiaRoot: pathFromFuchsiaRoot,
      doc: doc,
      exampleWidth: exampleWidth,
      exampleHeight: exampleHeight,
      hasSizeParam: hasSizeParam,
      classElement: c,
    );
  }

  /// Trims the leading document comment prefixes `/// ` from the raw comments.
  String _trimCommentPrefixes(String rawComment) {
    return rawComment
        .split('\n')
        .map((String line) => line.replaceFirst(new RegExp(r'^///[ \t]?'), ''))
        .join('\n');
  }
}

bool _isPublicFlutterWidget(ClassElement type) {
  // TODO(youngseokyoon): more thorough filtering
  return type.isPublic &&
      type.allSupertypes
          .any((InterfaceType superType) => superType.name == 'Widget');
}
