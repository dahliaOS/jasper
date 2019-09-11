// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mustache/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:strings/strings.dart' as strings;
// ignore: implementation_imports
import 'package:widget_explorer_core/src/utils.dart';
import 'package:widget_explorer_core/widget_specs.dart';

final DartFormatter _formatter = new DartFormatter();

Future<Null> main(List<String> args) async {
  String fuchsiaRoot = findFuchsiaRoot();

  String error = checkArgs(args, fuchsiaRoot);
  if (error != null) {
    stderr.writeln(error);
    stdout.writeln('Usage: pub run widget_explorer_gen.dart '
        '<output_dir> <widgets_package_dir> [<widgets_package_dir> ...]');
    exit(1);
  }

  String outputDir = args[0];
  List<String> packageDirs = args.sublist(1);

  List<WidgetSpecs> allWidgetSpecs = packageDirs
      .expand((String packageDir) =>
          extractWidgetSpecs(packageDir, fuchsiaRoot: fuchsiaRoot))
      .toList()
        ..sort();

  await writeIndex(outputDir, allWidgetSpecs);
  await Future.forEach(
    allWidgetSpecs,
    (WidgetSpecs specs) => writeWidgetSpecs(outputDir, specs),
  );
}

/// Try finding the fuchsia root from the current directory.
///
/// Walk up the directories until finding the .jiri_root directory. Returns null
/// if it fails to find the fuchsia root.
String findFuchsiaRoot() {
  Directory current = Directory.current;
  // ignore: literal_only_boolean_expressions
  while (true) {
    FileSystemEntity jiriRoot = current.listSync().firstWhere(
          (FileSystemEntity entity) =>
              path.basename(entity.path) == '.jiri_root' && entity is Directory,
          orElse: () => null,
        );

    if (jiriRoot != null) {
      return current.absolute.path;
    }

    // Break out if we reach the system root directory.
    Directory parent = current.parent;
    if (parent == current) {
      break;
    }

    current = parent;
  }

  return null;
}

/// Check if the provided arguments are valid.
///
/// Returns the reason when there is an error; returns null otherwise.
String checkArgs(List<String> args, String fuchsiaRoot) {
  if (args.length < 2) {
    return 'Invalid number of arguments.';
  }

  String outputDir = args[0];
  if (!new Directory(outputDir).existsSync()) {
    // Try creating the directory.
    try {
      new Directory(outputDir).createSync(recursive: true);
    } on Exception {
      return 'Could not create the output directory "$outputDir".';
    }
  }

  for (int i = 1; i < args.length; ++i) {
    String packageDir = args[i];
    if (!new Directory(packageDir).existsSync()) {
      return 'The specified package directory "$packageDir" does not exist.';
    }

    if (!new File(path.join(packageDir, 'pubspec.yaml')).existsSync()) {
      return 'The specified package directory "$packageDir" '
          'does not contain "pubspec.yaml" file.';
    }

    if (fuchsiaRoot != null) {
      // The fuchsia root dir should be an ancestor of the given package dir.
      if (!path.isWithin(fuchsiaRoot, packageDir)) {
        return 'The fuchsia root should be an ancestor of the package dir.';
      }
    }
  }

  return null;
}

const String _kHeader = '''
// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// THIS IS A GENERATED FILE. DO NOT MODIFY MANUALLY.''';

const String _kIndexFileTemplate = '''
{{ header }}

import 'package:widget_explorer_core/widget_specs.dart';
import 'package:widget_explorer_widgets/widget_explorer_widgets.dart';

{{ imports }}

/// Map of widget specs.
final Map<String, WidgetSpecs> kWidgetSpecs = <String, WidgetSpecs>{
{{ items }}
};

/// Map of generated widget state builders.
final Map<String, GeneratedStateBuilder> kStateBuilders = <String, GeneratedStateBuilder>{
{{ builders }}
};
''';

/// Writes the index file to the given output directory.
Future<Null> writeIndex(String outputDir, List<WidgetSpecs> widgetSpecs) async {
  String outputPath = path.join(outputDir, 'index.dart');

  Template template = new Template(
    _kIndexFileTemplate,
    htmlEscapeValues: false,
  );

  String imports = widgetSpecs.map((WidgetSpecs specs) {
    String underscoredName = strings.underscore(specs.name);
    return "import '$underscoredName.dart' as $underscoredName;";
  }).join('\n');

  String items = widgetSpecs.map((WidgetSpecs specs) {
    String underscoredName = strings.underscore(specs.name);
    return '  $underscoredName.kName: $underscoredName.kSpecs,';
  }).join('\n');

  String builders = widgetSpecs.map((WidgetSpecs specs) {
    String underscoredName = strings.underscore(specs.name);
    return '  $underscoredName.kName: $underscoredName.kBuilder,';
  }).join('\n');

  String output = template.renderString(<String, dynamic>{
    'header': _kHeader,
    'imports': imports,
    'items': items,
    'builders': builders,
  });

  await new File(outputPath).writeAsString(_formatter.format(output));
}

const String _kSpecFileTemplate = '''
{{ header }}

import 'package:flutter/material.dart';
import 'package:widget_explorer_core/widget_specs.dart';
import 'package:widget_explorer_widgets/widget_explorer_widgets.dart';
import 'package:{{ package_name }}/{{ path }}';

{{# additional_imports }}
import '{{ additional_import }}' as {{ import_id }};
{{/ additional_imports }}

/// Name of the widget.
const String kName = '{{ name }}';

/// [WidgetSpecs] of this widget.
final WidgetSpecs kSpecs = new WidgetSpecs(
  packageName: '{{ package_name }}',
  name: '{{ name }}',
  path: '{{ path }}',
  {{# path_from_fuchsia_root }}
  pathFromFuchsiaRoot: '{{ path_from_fuchsia_root }}',
  {{/ path_from_fuchsia_root }}
  doc: \'\'\'
{{ doc }}\'\'\',
  exampleWidth: {{ example_width }},
  exampleHeight: {{ example_height }},
  hasSizeParam: {{ has_size_param }},
);

/// Generated state object for this widget.
class _Generated{{ name }}State extends GeneratedState {
  {{# params }}
  {{ qualified_param_type }} {{ param_name }};
  {{/ params }}
  {{# generators }}
  {{ generator_declaration }};
  {{/ generators }}

  _Generated{{ name }}State(SetStateFunc setState) : super(setState);

  @override
  void initState(Map<String, dynamic> config) {
    {{# params }}
    {{ param_name }} = {{ param_initial_value }};
    {{/ params }}
  }

  @override
  Widget buildWidget(
    BuildContext context,
    Key key,
    double width,
    double height,
  ) {
    return new {{ name }}(
      key: key,
      {{# params }}
      {{ param_name }}: {{ param_expr }},
      {{/ params }}
    );
  }

  @override
  List<TableRow> buildParameterTableRows(BuildContext context) {
    return <TableRow>[
      {{# params }}
      buildTableRow(
        context,
        <Widget>[
          new Text('{{ param_type }}'),
          new Text('{{ param_name }}'),
          {{ param_controller }},
        ],
      ),
      {{/ params }}
    ];
  }
}

/// State builder for this widget.
final GeneratedStateBuilder kBuilder = (SetStateFunc setState) =>
    new _Generated{{ name }}State(setState);
''';

/// Writes the widget specs to the given output directory.
Future<Null> writeWidgetSpecs(String outputDir, WidgetSpecs specs) async {
  String underscoredName = strings.underscore(specs.name);
  String outputPath = path.join(outputDir, '$underscoredName.dart');

  Template template = new Template(
    _kSpecFileTemplate,
    htmlEscapeValues: false,
  );

  // Escape single quotes within the doc comments.
  String escapedDoc = _escapeQuotes(specs.doc);

  Set<String> additionalImports = new SplayTreeSet<String>();
  Map<String, String> importIdMap = <String, String>{};
  Set<DartType> generators = new SplayTreeSet<DartType>(
    (DartType t1, DartType t2) => t1.name.compareTo(t2.name),
  );
  List<ParameterElement> params = <ParameterElement>[];

  ConstructorElement constructor = specs.classElement.constructors.firstWhere(
      (ConstructorElement c) => c.isDefaultConstructor,
      orElse: () => null);

  if (constructor != null) {
    params = new List<ParameterElement>.from(constructor.parameters)
      ..removeWhere((ParameterElement param) => param.type.name == 'Key')
      ..forEach((ParameterElement param) =>
          _addImportForType(additionalImports, importIdMap, param.type));
  }

  // The parameter controllers / initial values should be generated here first
  // so that the additional imports can be safely added.
  List<Map<String, String>> paramList = params
      .map((ParameterElement param) => <String, String>{
            'qualified_param_type':
                _getQualifiedTypeName(importIdMap, param.type),
            'param_type': _getTypeName(param.type),
            'param_name': param.name,
            'param_controller': _generateParamControllerCode(
              additionalImports,
              importIdMap,
              generators,
              specs,
              param,
            ),
            'param_initial_value': _generateInitialValueCode(
              additionalImports,
              importIdMap,
              generators,
              specs,
              param,
            ),
            'param_expr': _generateParameterExpression(param),
          })
      .toList();

  List<Map<String, String>> generatorList = generators
      .map((DartType generatorType) => <String, String>{
            'generator_declaration':
                '${_getImportIdPrefixForType(importIdMap, generatorType)}'
                    '${generatorType.name} '
                    '${lowerCamelize(generatorType.name)} = '
                    'new ${_getImportIdPrefixForType(importIdMap, generatorType)}'
                    '${generatorType.name}()',
          })
      .toList();

  String output = template.renderString(<String, dynamic>{
    'header': _kHeader,
    'package_name': specs.packageName,
    'name': specs.name,
    'path': specs.path,
    'path_from_fuchsia_root': specs.pathFromFuchsiaRoot != null
        ? <String, String>{'path_from_fuchsia_root': specs.pathFromFuchsiaRoot}
        : null,
    'doc': escapedDoc,
    'example_width': _doubleValueToCode(specs.exampleWidth),
    'example_height': _doubleValueToCode(specs.exampleHeight),
    'has_size_param': specs.hasSizeParam,
    'additional_imports': additionalImports
        .map((String uri) => <String, String>{
              'additional_import': uri,
              'import_id': importIdMap[uri],
            })
        .toList(),
    'params': paramList,
    'generators': generatorList,
  });

  await new File(outputPath).writeAsString(_formatter.format(output));
}

String _generateParamControllerCode(
  Set<String> additionalImports,
  Map<String, String> importIdMap,
  Set<DartType> generators,
  WidgetSpecs specs,
  ParameterElement param,
) {
  // TODO(youngseokyoon): handle more types of values.

  // Handle size parameters.
  if (_isWidthParam(param)) {
    return "new InfoText('width value is used')";
  }

  if (_isHeightParam(param)) {
    return "new InfoText('height value is used')";
  }

  if (_isSizeParam(param)) {
    return "new InfoText('size value is used')";
  }

  // For int type, use a TextField where the user can type in the integer value.
  if (param.type.name == 'int') {
    return '''new TextFieldWithInitialValue(
      initialValue: (${param.name} ?? 0).toString(),
      keyboardType: TextInputType.number,
      onChanged: (String value) {
        try {
          int intValue = int.parse(value);
          setState(() {
            ${param.name} = intValue;
          });
        } catch (e) {
          // Do nothing.
        }
      },
    )''';
  }

  // For bool type, use a Switch widget.
  // Since we don't want the Switch widget to take up the entire width, add an
  // empty widget next to it.
  if (param.type.name == 'bool') {
    return '''new Row(
      children: <Widget>[
        new Switch(
          value: ${param.name} ?? false,
          onChanged: (bool value) {
            setState(() {
              ${param.name} = value;
            });
          },
        ),
        new Expanded(child: new Container()),
      ],
    )''';
  }

  // For double type, use a TextField where the user can type the value.
  if (param.type.name == 'double') {
    return '''new TextFieldWithInitialValue(
        initialValue: (${param.name} ?? 0.0).toString(),
        keyboardType: TextInputType.number,
        onChanged: (String value) {
          try {
            double doubleValue = double.parse(value);
            setState(() {
              ${param.name} = doubleValue;
            });
          } catch (e) {
            // Do nothing.
          }
        },
      )''';
  }

  // For String type, use a TextField where the user can type in the value.
  if (param.type.name == 'String') {
    // If this parameter should be retrieved from the config.json file, do not
    // show the values on the screen.
    String configKey = specs.getConfigKey(param);
    if (configKey != null) {
      return """new ConfigKeyText(
        configKey: '${_escapeQuotes(configKey)}',
        configValue: ${param.name},
      )""";
    }

    return '''new TextFieldWithInitialValue(
      initialValue: ${param.name},
      onChanged: (String value) {
        setState(() {
          ${param.name} = value;
        });
      },
    )''';
  }

  // Handle enum parameters with a popup menu button.
  if (_isEnumParameter(param)) {
    return '''new PopupMenuButton<${_getQualifiedTypeName(importIdMap, param.type)}>(
      itemBuilder: (BuildContext context) {
        return ${_getQualifiedTypeName(importIdMap, param.type)}.values.map((${_getQualifiedTypeName(importIdMap, param.type)} value) {
          return new PopupMenuItem<${_getQualifiedTypeName(importIdMap, param.type)}>(
            value: value,
            child: new Text(value.toString()),
          );
        }).toList();
      },
      initialValue: ${_getQualifiedTypeName(importIdMap, param.type)}.values[0],
      onSelected: (${_getQualifiedTypeName(importIdMap, param.type)} value) {
        setState(() {
          ${param.name} = value;
        });
      },
      child: new Text((${param.name} ?? 'null').toString()),
    )''';
  }

  // Handle callback parameters.
  if (_isCallbackParameter(param)) {
    return "new InfoText('Default implementation')";
  }

  // Handle parameters with a specified generator.
  ElementAnnotation generatorAnnotation = _getGenerator(param);
  if (generatorAnnotation != null) {
    DartObject generatorObj = generatorAnnotation.computeConstantValue();
    DartType generatorType = generatorObj.getField('type').toTypeValue();
    String methodName = generatorObj.getField('methodName').toStringValue();

    // Add the generator type to the list of additional imports and generators.
    _addImportForType(additionalImports, importIdMap, generatorType);
    generators.add(generatorType);

    // The actual code to invoke (e.g. `modelFixtures.thread()`).
    String generatorInvocationCode =
        _getGeneratorInvocationCode(generatorType, methodName);

    // Place a button widget for regenerating the value.
    return '''new RegenerateButton(
      onPressed: () {
        setState(() {
          ${param.name} = $generatorInvocationCode;
        });
      },
      codeToDisplay: '${_escapeQuotes(generatorInvocationCode)}',
    )''';
  }

  return "new InfoText('null (this type of parameter is not supported yet)')";
}

String _generateInitialValueCode(
  Set<String> additionalImports,
  Map<String, String> importIdMap,
  Set<DartType> generators,
  WidgetSpecs specs,
  ParameterElement param,
) {
  // See if there is an example value specified.
  dynamic value = specs.getExampleValue(param);
  if (value != null) {
    switch (value.runtimeType) {
      case int:
      case bool:
      case double:
        return value.toString();
      case String:
        return "'''${_escapeQuotes(value.toString())}'''";
      default:
        return 'null';
    }
  }

  // Retrieve the config value associated with the specified config key.
  String configKey = specs.getConfigKey(param);
  if (configKey != null) {
    return "config['${_escapeQuotes(configKey)}']";
  }

  // TODO(youngseokyoon): See if the parameter type has a default constructor
  // that can be used.
  // if (param.type.element is ClassElement) {
  //   ClassElement type = param.type.element;
  //   if (type.constructors
  //       .any((ConstructorElement c) => c.isDefaultConstructor)) {
  //     return 'new ${param.type.name}()';
  //   }
  // }

  // Handle primitive types.
  switch (param.type.name) {
    case 'int':
      return '0';
    case 'bool':
      return 'false';
    case 'double':
      return '0.0';
    case 'String':
      return "''";
  }

  // Handle enum types.
  if (_isEnumParameter(param)) {
    return '${_getQualifiedTypeName(importIdMap, param.type)}.values[0]';
  }

  // Handle callback parameters.
  if (_isCallbackParameter(param)) {
    FunctionTypedElement func = param.type.element;
    String functionName = '${specs.name}.${param.name}';

    // Print out all the parameter values to the console.
    if (func.parameters.isNotEmpty) {
      String paramList = func.parameters
          .map((ParameterElement p) => 'dynamic ${p.name}')
          .join(', ');
      String valueList =
          func.parameters.map((ParameterElement p) => p.name).join(', ');
      return "($paramList) => print('$functionName called "
          "with parameters: \${<dynamic>[$valueList]}')";
    }

    // If the callback function has no parameters, just say it was called.
    return "() => print('$functionName called')";
  }

  // Handle parameters with a specified generator.
  ElementAnnotation generatorAnnotation = _getGenerator(param);
  if (generatorAnnotation != null) {
    DartObject generatorObj = generatorAnnotation.computeConstantValue();
    DartType generatorType = generatorObj.getField('type').toTypeValue();
    String methodName = generatorObj.getField('methodName').toStringValue();

    // Place a button widget for regenerating the value.
    return _getGeneratorInvocationCode(generatorType, methodName);
  }

  // Otherwise, return 'null';
  return 'null';
}

String _generateParameterExpression(ParameterElement param) {
  if (_isWidthParam(param)) {
    return 'width';
  }

  if (_isHeightParam(param)) {
    return 'height';
  }

  if (_isSizeParam(param)) {
    // In this case, the width and height value must be the same, and it doesn't
    // matter which one we use. Just using the width value here.
    return 'width';
  }

  return 'this.${param.name}';
}

/// Returns the display name of the given type.
///
/// If the type has generic type arguments, returns 'dynamic' instead, to avoid
/// having to deal with analyzer errors for now.
String _getTypeName(DartType type) {
  // TODO(youngseokyoon): Handle generic type arguments correctly.
  // https://fuchsia.atlassian.net/browse/SO-259
  if (type is ParameterizedType) {
    ParameterizedType parameterizedType = type;
    if (parameterizedType.typeArguments?.isNotEmpty ?? false) {
      return 'dynamic';
    }
  }

  return type.name;
}

/// Determines whether the provided parameter is of an enum type.
bool _isEnumParameter(ParameterElement param) {
  if (param?.type?.element is! ClassElement) {
    return false;
  }

  ClassElement paramType = param.type.element;
  return paramType.isEnum;
}

/// Determines whether the provided parameter represents a callback function.
///
/// We consider any function parameter with a void return type as a callback.
bool _isCallbackParameter(ParameterElement param) {
  if (param?.type?.element is! FunctionTypedElement) {
    return false;
  }

  FunctionTypedElement func = param.type.element;
  return func.returnType.isVoid;
}

/// Gets the @Generator annotation of the given parameter.
ElementAnnotation _getGenerator(ParameterElement param) {
  ElementAnnotation annotation;

  // An @Generator annotation on the parameter itself has a higher priority.
  annotation = getAnnotationWithName(param, 'Generator');
  if (annotation != null) {
    return annotation;
  }

  // Also see if the parameter type (class) has an @Generator annotation.
  return annotation = getAnnotationWithName(param?.type?.element, 'Generator');
}

/// Gets the code for invoking the generator.
String _getGeneratorInvocationCode(DartType generatorType, String methodName) {
  return '${lowerCamelize(generatorType.name)}.$methodName()';
}

bool _isWidthParam(ParameterElement param) {
  return getAnnotationWithName(param, '_WidthParam') != null;
}

bool _isHeightParam(ParameterElement param) {
  return getAnnotationWithName(param, '_HeightParam') != null;
}

bool _isSizeParam(ParameterElement param) {
  return getAnnotationWithName(param, '_SizeParam') != null;
}

/// Escape all single quotes in the given string with a leading backslash,
/// except for the ones already escaped.
String _escapeQuotes(String str) {
  return str?.replaceAllMapped(
    new RegExp(r"([^\\])'"),
    (Match m) => "${m.group(1)}\\\'",
  );
}

void _addImportForType(
  Set<String> additionalImports,
  Map<String, String> importIdMap,
  DartType type,
) {
  Uri importUri = type?.element?.librarySource?.uri;
  String importUriString = importUri?.toString();
  if (importUriString != null &&
      importUriString != 'dart:core' &&
      !additionalImports.contains(importUriString)) {
    additionalImports.add(importUriString);
    // Specify an identifier (i.e. import '..' as foo) to avoid name collision.
    String idBase = strings.underscore(
      path.basenameWithoutExtension(importUri.pathSegments.last),
    );
    String id = idBase;

    // Here, just in case the import id name is already in use, add a number at
    // the end of the id name by increasing the number until it doesn't collide
    // with an existing id.
    int count = 1;
    while (importIdMap.values.contains(id)) {
      ++count;
      id = '$idBase$count';
    }
    importIdMap[importUriString] = id;
  }
}

/// Returns the import identifier prefix for the given type.
///
/// For example, if "foo.dart" was imported as "foo",
///     import 'foo.dart' as foo;
///
/// and the `Foo` type was given as the second parameter, this function returns
/// `'foo.'` with the trailing dot.
///
/// Otherwise, this function returns empty string.
String _getImportIdPrefixForType(
  Map<String, String> importIdMap,
  DartType type,
) {
  String importUriString = type?.element?.librarySource?.uri?.toString();
  String importId = importIdMap[importUriString];
  return importId != null ? '$importId.' : '';
}

/// Returns the fully qualified name for the given type.
String _getQualifiedTypeName(
  Map<String, String> importIdMap,
  DartType type,
) {
  String typeName = _getTypeName(type);
  String prefix =
      typeName == 'dynamic' ? '' : _getImportIdPrefixForType(importIdMap, type);
  return '$prefix$typeName';
}

String _doubleValueToCode(double value) {
  if (value == double.nan) {
    return 'double.NAN';
  } else if (value == double.infinity) {
    return 'double.infinity';
  } else if (value == double.negativeInfinity) {
    return 'double.negativeInfinity';
  } else if (value == double.minPositive) {
    return 'double.MIN_POSITIVE';
  } else if (value == double.maxFinite) {
    return 'double.MAX_FINITE';
  } else if (value == null) {
    return 'null';
  }

  return value.toString();
}
