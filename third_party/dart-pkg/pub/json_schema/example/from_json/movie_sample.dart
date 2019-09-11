#!/usr/bin/env dart

import "package:json_schema/json_schema.dart";
import "package:logging/logging.dart";

main() {
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  Logger.root.level = Level.SHOUT;

  //////////////////////////////////////////////////////////////////////
  // Define schema in code
  //////////////////////////////////////////////////////////////////////
  var movieSchema = {
    "title" : "movie data",
    "additionalProperties" : false,
    "required" : [ "movies" ],
    "properties" : {
      "movies" : { r"$ref" : "#/definitions/movie_map" }
    },
    "definitions" : {
      "movie" : {
        "additionalProperties": false,
        "required" : [ "title", "year_made", "rating" ],
        "properties": {
          "title" : { "type" : "string" },
          "year_made" : { "type" : "integer" },
          "rating" : { "type" : "integer" }
        }
      },
      "movie_map" : {
        "type": "object",
        "additionalProperties": { r"$ref": "#/definitions/movie" },
        "default": {}
      }
    }
  };

  var movies = {
    "movies" : {
      "the mission" : {
        "title":"The Mission",
        "year_made":1986,
        "rating":5
      },
      "troll 2" : {
        "title":"Troll 2",
        "year_made":1990,
        "rating":2
      }
    }
  };

  Schema.createSchema(movieSchema)
    .then((schema) {
      var validator = new Validator(schema);
      bool validates = validator.validate(movies);
      if(!validates) {
        print("Errors: ${validator.errors}");
      } else {
        print('$movies:\nvalidates!');
      }
    });

}
