#!/usr/bin/env dart
import "dart:convert" as convert;
import "package:json_schema/json_schema.dart";
import "package:logging/logging.dart";

main() {
  Logger.root.onRecord.listen((LogRecord rec) =>
      print('${rec.level.name}: ${rec.time}: ${rec.message}'));
  Logger.root.level = Level.SHOUT;

  //////////////////////////////////////////////////////////////////////
  // Pull in schema from web
  //////////////////////////////////////////////////////////////////////
  String url = "http://json-schema.org/draft-04/schema";
  Schema.createSchemaFromUrl(url).then((Schema schema) {
    // TODO: Figure out the redirect issues here
    if (false) {
      print('''Does schema validate itself?
          ${schema.validate(schema.schemaMap)}''');
    }

    var validSchema = {"type": "integer"};
    print('''Does schema validate valid schema $validSchema?
  ${schema.validate(validSchema)}''');

    var invalidSchema = {"type": "nibble"};
    print('''Does schema validate invalid schema $invalidSchema?
  ${schema.validate(invalidSchema)}''');
  });

  //////////////////////////////////////////////////////////////////////
  // Pull in schema from file in current directory
  //////////////////////////////////////////////////////////////////////
  url = "grades_schema.json";
  Schema.createSchemaFromUrl(url).then((schema) {
    var grades = convert.json.decode('''
{
    "semesters": [
        {
            "semester": 1,
            "grades": [
                {
                    "type": "homework",
                    "date": "09/27/2013",
                    "grade": 100,
                    "avg": 93,
                    "std": 8
                },
                {
                    "type": "homework",
                    "date": "09/28/2013",
                    "grade": 100,
                    "avg": 60,
                    "std": 25
                }
            ]
        }
      ]
}''');

    print('''Does grades schema validate $grades
  ${schema.validate(grades)}''');
  });
}
