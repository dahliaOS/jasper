import 'dart:io';
import 'package:path/path.dart';
import 'package:json_schema/json_schema.dart';
import 'package:json_schema/schema_dot.dart';

main() {
  var sourcePath = join(dirname(dirname(absolute(Platform.script.toFilePath()))),
      'dot_samples', 'schemas');
  var outPath = join(dirname(sourcePath), 'schemaout');
  new Directory(sourcePath).listSync().forEach((jsonFile) {
    var fname = jsonFile.path;
    var base = basenameWithoutExtension(fname);
    var dotFilename = join(outPath, '$base.dot');
    var pngOut = join(outPath, '$base.png');

    Schema.createSchemaFromUrl(fname)
      .then((schema) {
        new File(dotFilename).writeAsStringSync(createDot(schema));
      })
      .then((_) {

        Process.run('dot', ['-Tpng', '-o$pngOut', dotFilename])
          .then((ProcessResult processResult) {
            if(processResult.exitCode == 0) {
              print("Finished running dot -Tpng -o$pngOut $fname");
            } else {
              print("FAILED: running dot -Tpng -o$pngOut $fname");
            }
          });
      });
  });
}