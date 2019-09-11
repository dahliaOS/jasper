import "dart:io";
import "package:path/path.dart" as path;
import "package:ebisu/ebisu_dart_meta.dart";
import "package:ebisu/ebisu.dart";
import "package:logging/logging.dart";

String _topDir;

void main() {
  Logger.root.onRecord.listen((LogRecord r) =>
      print("${r.loggerName} [${r.level}]:\t${r.message}"));
  String here = path.absolute(Platform.script.toFilePath());
  _topDir = path.dirname(path.dirname(here));
  useDartFormatter = true;
  System ebisu = system('json_schema')
    ..pubSpec.homepage = 'https://github.com/patefacio/json_schema'
    ..pubSpec.version = '1.0.4'
    ..pubSpec.doc = 'Provide support for validating instances against json schema'
    ..rootPath = '$_topDir'
    ..doc = 'Json Schema related functionality'
    ..testLibraries = [
      library('test_invalid_schemas')
      ..includesLogger = true
      ..imports = [
        'io', '"dart:convert" as convert', '"package:path/path.dart" as path',
        'package:json_schema/json_schema.dart',
      ],
      library('test_validation')
      ..includesLogger = true
      ..imports = [
        'io', '"dart:convert" as convert', '"package:path/path.dart" as path',
        'package:json_schema/json_schema.dart',
      ],
    ]
    ..scripts = [
      script('schemadot')
      ..imports = [
        'package:json_schema/json_schema.dart',
        'package:json_schema/schema_dot.dart',
        '"dart:convert" as convert',
        'math',
        'async',
      ]
      ..doc = '''

Usage: schemadot --in-uri INPUT_JSON_URI --out-file OUTPUT_FILE

Given an input uri [in-uri] processes content of uri as
json schema and generates input file for Graphviz dot
program. If [out-file] provided, output is written to
the file, otherwise written to stdout.
'''
      ..args = [
        scriptArg('in_uri')
        ..isRequired = true
        ..abbr = 'i',
        scriptArg('out_file')
        ..abbr = 'o',
      ]
    ]
    ..libraries = [
      library('schema_dot')
      ..doc = 'Functionality to create Graphviz input dot file from schema'
      ..imports = [
        'package:json_schema/json_schema.dart',
        'convert',
        'async',
      ]
      ..classes = [
        class_('schema_node')
        ..doc = 'Represents one node in the schema diagram'
        ..members = [
          member('schema')
          ..doc = 'Referenced schema this node portrays'
          ..type = 'Schema',
          member('links')
          ..doc = 'List of links (resulting in graph edge) from this node to another'
          ..type = 'List<String>'
        ]
      ],
      library('json_schema')
      ..doc = 'Support for validating json instances against a json schema'
      ..includesLogger = true
      ..enums = [
        enum_('schema_type')
        ..isSnakeString = true
        ..hasCustom = true
        ..values = [
          id('array'), id('boolean'), id('integer'),
          id('number'), id('null'), id('object'),
          id('string')
        ]
      ]
      ..imports = [
        'io',
        'math',
        '"dart:convert" as convert',
        '"package:path/path.dart" as PATH',
        'async',
      ]
      ..parts = [
        part('schema')
        ..classes = [
          class_('schema')
          ..defaultMemberAccess = RO
          ..ctorCustoms = [ '_fromRootMap', '_fromMap' ]
          ..doc = '''
Constructed with a json schema, either as string or Map. Validation of
the schema itself is done on construction. Any errors in the schema
result in a FormatException being thrown.
'''
          ..members = [
            member('root')
            ..type = 'Schema'
            ..ctors = [ '_fromMap' ],
            member('schema_map')
            ..type = 'Map'
            ..classInit = '{}'
            ..ctors = [ '_fromRootMap', '_fromMap' ],
            member('path')
            ..ctorInit = "'#'"
            ..ctors = [ '_fromMap' ],

            member('multiple_of')
            ..type = 'num',
            member('maximum')
            ..type = 'num',
            member('exclusive_maximum')
            ..type = 'bool'
            ..access = IA,
            member('minimum')
            ..type = 'num',
            member('exclusive_minimum')
            ..type = 'bool'
            ..access = IA,
            member('max_length')
            ..type = 'int',
            member('min_length')
            ..type = 'int',
            member('pattern')
            ..type = 'RegExp',

            // Validation keywords for any instance
            member('enum_values')
            ..type = 'List'
            ..classInit = '[]',
            member('all_of')
            ..type = 'List<Schema>'
            ..classInit = '[]',
            member('any_of')
            ..type = 'List<Schema>'
            ..classInit = '[]',
            member('one_of')
            ..type = 'List<Schema>'
            ..classInit = '[]',
            member('not_schema')
            ..type = 'Schema',
            member('definitions')
            ..type = 'Map<String,Schema>'
            ..classInit = '{}',

            // Meta-data
            member('id')
            ..type = 'Uri',
            member('ref'),
            member('description'),
            member('title'),

            member('schema_type_list')
            ..type = 'List<SchemaType>',
            member('items')
            ..doc = 'To match all items to a schema'
            ..type = 'Schema',
            member('items_list')
            ..doc = 'To match each item in array to a schema'
            ..type = 'List<Schema>',
            member('additional_items')
            ..type = 'dynamic',
            member('max_items')
            ..type = 'int',
            member('min_items')
            ..type = 'int',
            member('unique_items')
            ..type = 'bool'
            ..classInit = 'false',

            member('required_properties')
            ..type = 'List<String>',
            member('max_properties')
            ..type = 'int',
            member('min_properties')
            ..type = 'int'
            ..classInit = '0',
            member('properties')
            ..type = 'Map<String,Schema>'
            ..classInit = '{}',
            member('additional_properties')
            ..type = 'bool',
            member('additional_properties_schema')
            ..type = 'Schema',
            member('pattern_properties')
            ..type = 'Map<RegExp,Schema>'
            ..classInit = '{}',

            member('schema_dependencies')
            ..type = 'Map<String,Schema>'
            ..classInit = '{}',
            member('property_dependencies')
            ..type = 'Map<String,List<String>>'
            ..classInit = '{}',

            member('default_value')
            ..type = 'dynamic',

            member('ref_map')
            ..doc = 'Map of path to schema object'
            ..type = 'Map<String,Schema>'
            ..classInit = '{}',
            member('schema_refs')
            ..doc = 'For schemas with \$ref maps path of schema to \$ref path'
            ..type = 'Map<String,String>'
            ..access = IA
            ..classInit = '{}',
            member('schema_assignments')
            ..doc = 'Assignments to call for resolution upon end of parse'
            ..type = 'List'
            ..classInit = '[]'
            ..access = IA,
            member('free_form_map')
            ..doc = 'Maps any non-key top level property to its original value'
            ..type = 'Map<String,dynamic>'
            ..classInit = '{}'
            ..access = IA,
            member('this_completer')
            ..type = 'Completer'
            ..classInit = 'new Completer()'
            ..access = IA,
            member('retrieval_requests')
            ..type = 'List<Future<Schema>>'
            ..init = []
            ..access = IA,
            member('paths_encountered')
            ..doc = 'Set of strings to gaurd against path cycles'
            ..type = 'Set<String>'
            ..classInit = 'new Set()'
            ..access = IA,
            member('format')
            ..doc = 'Support for optional formats (date-time, uri, email, ipv6, hostname)'
            ..access = IA,
          ]
        ],
        part('validator')
      ..variables = [
        variable('email_re')
        ..isPublic = false
        ..type = 'RegExp'
        ..init = "new RegExp(\n"
        r'''
  r'^[_A-Za-z0-9-\+]+(\.[_A-Za-z0-9-]+)*'
  r'@'
  r'[A-Za-z0-9-]+(\.[A-Za-z0-9]+)*(\.[A-Za-z]{2,})$'
'''
        ")",
        variable('default_email_validator')
        ..type = 'var'
        ..isPublic = false
        ..init = '(String email) => _emailRe.firstMatch(email) != null',
        variable('email_validator')
        ..isPublic = false
        ..type = 'var'
        ..init = '_defaultEmailValidator',
        variable('ipv4_re')
        ..isPublic = false
        ..type = 'RegExp'
        ..init = "new RegExp(\n"
        r'''
  r'^(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.'
  r'(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.'
  r'(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.'
  r'(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))$'
'''
        ")",
        variable('ipv6_re')
        ..isPublic = false
        ..type = 'RegExp'
        ..init = "new RegExp(\n"
        r'''
  r'(^([0-9a-f]{1,4}:){1,1}(:[0-9a-f]{1,4}){1,6}$)|'
  r'(^([0-9a-f]{1,4}:){1,2}(:[0-9a-f]{1,4}){1,5}$)|'
  r'(^([0-9a-f]{1,4}:){1,3}(:[0-9a-f]{1,4}){1,4}$)|'
  r'(^([0-9a-f]{1,4}:){1,4}(:[0-9a-f]{1,4}){1,3}$)|'
  r'(^([0-9a-f]{1,4}:){1,5}(:[0-9a-f]{1,4}){1,2}$)|'
  r'(^([0-9a-f]{1,4}:){1,6}(:[0-9a-f]{1,4}){1,1}$)|'
  r'(^(([0-9a-f]{1,4}:){1,7}|:):$)|'
  r'(^:(:[0-9a-f]{1,4}){1,7}$)|'
  r'(^((([0-9a-f]{1,4}:){6})(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})$)|'
  r'(^(([0-9a-f]{1,4}:){5}[0-9a-f]{1,4}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})$)|'
  r'(^([0-9a-f]{1,4}:){5}:[0-9a-f]{1,4}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}$)|'
  r'(^([0-9a-f]{1,4}:){1,1}(:[0-9a-f]{1,4}){1,4}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}$)|'
  r'(^([0-9a-f]{1,4}:){1,2}(:[0-9a-f]{1,4}){1,3}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}$)|'
  r'(^([0-9a-f]{1,4}:){1,3}(:[0-9a-f]{1,4}){1,2}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}$)|'
  r'(^([0-9a-f]{1,4}:){1,4}(:[0-9a-f]{1,4}){1,1}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}$)|'
  r'(^(([0-9a-f]{1,4}:){1,5}|:):(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}$)|'
  r'(^:(:[0-9a-f]{1,4}){1,5}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}$)'
'''
        ")",
        variable('default_uri_validator')
        ..type = 'var'
        ..isPublic = false
        ..init = '''
(String uri) {
  try {
    final result = Uri.parse(uri);
    if(result.path.startsWith('//')) return false;
    return true;
  } catch(e) {
    return false;
  }
}''',
        variable('hostname_re')
        ..isPublic = false
        ..type = 'RegExp'
        ..init = "new RegExp(\n"
        r'''
  r'^(?=.{1,255}$)'
  r'[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?'
  r'(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$'
'''
        ")",
        variable('uri_validator')
        ..isPublic = false
        ..type = 'var'
        ..init = '_defaultUriValidator',
      ]
        ..classes = [
          class_('validator')
          ..defaultMemberAccess = IA
          ..doc = 'Initialized with schema, validates instances against it'
          ..members = [
            member('root_schema')
            ..type = 'Schema'
            ..ctors = [''],
            member('errors')
            ..type = 'List<String>'
            ..access = RO
            ..classInit = '[]',
            member('report_multiple_errors')
            ..type = 'bool',
          ],
        ]
      ]
    ];
  ebisu.generate();
}
