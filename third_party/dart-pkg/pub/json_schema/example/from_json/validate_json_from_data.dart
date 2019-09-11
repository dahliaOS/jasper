#!/usr/bin/env dart

import "package:json_schema/json_schema.dart";
import "package:logging/logging.dart";

main() {

  Logger.root.onRecord.listen((LogRecord rec) =>
    print('${rec.level.name}: ${rec.time}: ${rec.message}'));
  Logger.root.level = Level.SHOUT;

  //////////////////////////////////////////////////////////////////////
  // Define schema in code
  //////////////////////////////////////////////////////////////////////
  var mustBeIntegerSchema = {
    "type" : "integer"
  };

  var n = 3;
  var decimals = 3.14;
  var str = 'hi';

  Schema.createSchema(mustBeIntegerSchema)
    .then((schema) {
      print('$n => ${schema.validate(n)}');
      print('$decimals => ${schema.validate(decimals)}');
      print('$str => ${schema.validate(str)}');
    });

}
