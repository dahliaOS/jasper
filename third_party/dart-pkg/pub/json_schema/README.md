# Json Schema

  A *dart:io* dependent library for validating json instances against json schema (version Draft 04)

![Build Status](https://travis-ci.org/patefacio/json_schema.svg)


# How To Validate

  To validate instances against a schema first create the schema, then
  call validate on it with an json instance. This can be done with an
  url:

### Example 1  

    String url = "http://json-schema.org/draft-04/schema";
    Schema.createSchemaFromUrl(url)
      .then((schema) {
        print('Does schema validate itself? ${schema.validate(schema.schemaMap)}');
      });

  In this example a schema is created from the url and its stored
  contents are validated against itself. Since the referenced schema
  is the schema for schemas and the instance is, of course, a schema,
  the result prints true.

### Example 2
  
  An url can point to a local file, either of format
  _file:///absolute\_path\_to/schema.json_ or _subfolder/schema.json_
  where _subfolder_ is a subfolder of current working directory. An
  example of this can be found in
  _example/from\_url/validate\_instance\_from\_url.dart_

      url = "grades_schema.json";
      Schema.createSchemaFromUrl(url)
        .then((schema) {
          var grades = JSON.parse('''
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

  In this example the schema is read from file _grades\_schema.json_
  in the current directory and a valid instance is submitted for
  validation (in the string of the print statement). This example also
  prints true.

### Example 3

  A schema can be created with a Map that is either hand-crafted or
  the result of a call to json parse.

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

  This example creates a schema requiring the type be integer. It then
  tests against three instances with the following results:

    3 => true
    3.14 => false
    hi => false

# How To Use Schema Information

  Schema information can be used for validation; but it can also be a
  valuable source of information about the structure of data. The
  Schema class provided here works by fully parsing the schema first,
  which itself must be valid on all paths within the schema. The only
  invalid content of a provided schema are _free-form properties_
  containing schema that are not referenced. Accessors are provided
  for the meta-data associated with a schema, so tools can do *stuff*
  with it. 

  One example use is the _schemadot_ program included in the _bin_
  folder which takes schema as input and outputs a _Graphviz_ _dot_
  file, providing a picture of the schema. This does not provide all
  information of the schema, and is a work in progress - but it can be
  useful to *see* what a schema is.

  For example, the grades_schema.json is:

    {
        "$schema": "http://json-schema.org/draft-04/schema#",
        "title" : "Grade Tracker",
        "type" : "object",
        "additionalProperties" : false,
        "properties" : {
    	"semesters" : {
    	    "type" : "array",
    	    "items" : {
                    "type" : "object",
                    "additionalProperties" : false,
                    "properties" : {
                        "semester": { "type" : "integer" },
                        "grades" : {
                            "type" : "array",
                            "items" : {
                                "type" : "object",
                                "additionalProperties" : false,
                                "required" : [ "date", "type", "grade", "std" ],
                                "properties" : {
                                    "date" : { "type" : "string"},
                                    "type" : { "enum" : [ "homework", "quiz", "test", "final_exam" ] },
                                    "grade" : { "type" : "number"},
                                    "std" : { 
                                        "oneOf" : [ 
                                            {"type" : "number"}, 
                                            {"type" : "null"}
                                        ] 
                                    },
                                    "avg" : { 
                                        "oneOf" : [ 
                                            {"type" : "number"}, 
                                            {"type" : "null"}
                                        ] 
                                    }
                                }
                            }
                        }
                    }
                }
      	    }
        }
    }

  And the generated image is:

  ![Grades!](https://raw.github.com/patefacio/json_schema/master/example/from_url/grades_schema.png)  

  For more detailed image open link:
  <a href="https://raw.github.com/patefacio/json_schema/master/example/from_url/grades_schema.png"
  target="_blank">Grade example schema diagram</a>

# TODOS
  
  * Add a remote ref test that does not require files vended from local host
  * Add support for optional tests: format
