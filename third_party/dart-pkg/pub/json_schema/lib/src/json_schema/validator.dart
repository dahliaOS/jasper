part of json_schema.json_schema;

/// Initialized with schema, validates instances against it
class Validator {
  Validator(this._rootSchema);

  List<String> get errors => _errors;

  // custom <class Validator>

  /// Validate the [instance] against the this validator's schema
  bool validate(dynamic instance, [bool reportMultipleErrors = false]) {
    _logger
        .info("Validating ${instance.runtimeType}:$instance on ${_rootSchema}");

    _reportMultipleErrors = reportMultipleErrors;
    _errors = [];
    if (!_reportMultipleErrors) {
      try {
        _validate(_rootSchema, instance);
        return true;
      } on FormatException {
        return false;
      } catch (e) {
        _logger.shout("Unexpected Exception: $e");
        return false;
      }
    }

    _validate(_rootSchema, instance);
    return _errors.length == 0;
  }

  static bool _typeMatch(SchemaType type, dynamic instance) {
    switch (type) {
      case SchemaType.OBJECT:
        return instance is Map;
      case SchemaType.STRING:
        return instance is String;
      case SchemaType.INTEGER:
        return instance is int;
      case SchemaType.NUMBER:
        return instance is num;
      case SchemaType.ARRAY:
        return instance is List;
      case SchemaType.BOOLEAN:
        return instance is bool;
      case SchemaType.NULL:
        return instance == null;
    }
    return false;
  }

  void _numberValidation(Schema schema, num n) {
    var maximum = schema._maximum;
    var minimum = schema._minimum;
    if (maximum != null) {
      if (schema.exclusiveMaximum) {
        if (n >= maximum) {
          _err("${schema._path}: maximum exceeded ($n >= $maximum)");
        }
      } else {
        if (n > maximum) {
          _err("${schema._path}: maximum exceeded ($n > $maximum)");
        }
      }
    } else if (minimum != null) {
      if (schema.exclusiveMinimum) {
        if (n <= minimum) {
          _err("${schema._path}: minimum violated ($n <= $minimum)");
        }
      } else {
        if (n < minimum) {
          _err("${schema._path}: minimum violated ($n < $minimum)");
        }
      }
    }

    var multipleOf = schema._multipleOf;
    if (multipleOf != null) {
      if (multipleOf is int && n is int) {
        if (0 != n % multipleOf) {
          _err("${schema._path}: multipleOf violated ($n % $multipleOf)");
        }
      } else {
        double result = n / multipleOf;
        if (result.truncate() != result) {
          _err("${schema._path}: multipleOf violated ($n % $multipleOf)");
        }
      }
    }
  }

  void _typeValidation(Schema schema, dynamic instance) {
    var typeList = schema._schemaTypeList;
    if (typeList != null && typeList.length > 0) {
      if (!typeList.any((type) => _typeMatch(type, instance))) {
        _err("${schema._path}: type: wanted ${typeList} got $instance");
      }
    }
  }

  void _enumValidation(Schema schema, dynamic instance) {
    var enumValues = schema._enumValues;
    if (enumValues.length > 0) {
      try {
        enumValues.singleWhere((v) => _jsonEqual(instance, v));
      } on StateError {
        _err("${schema._path}: enum violated ${instance}");
      }
    }
  }

  void _stringValidation(Schema schema, String instance) {
    int actual = instance.length;
    var minLength = schema._minLength;
    var maxLength = schema._maxLength;
    if (maxLength is int && actual > maxLength) {
      _err("${schema._path}: maxLength exceeded ($instance vs $maxLength)");
    } else if (minLength is int && actual < minLength) {
      _err("${schema._path}: minLength violated ($instance vs $minLength)");
    }
    var pattern = schema._pattern;
    if (pattern != null && !pattern.hasMatch(instance)) {
      _err("${schema._path}: pattern violated ($instance vs $pattern)");
    }
  }

  void _itemsValidation(Schema schema, dynamic instance) {
    int actual = instance.length;

    var singleSchema = schema._items;
    if (singleSchema != null) {
      instance.forEach((item) => _validate(singleSchema, item));
    } else {
      var items = schema._itemsList;
      var additionalItems = schema._additionalItems;

      if (items != null) {
        int expected = items.length;
        int end = min(expected, actual);
        for (int i = 0; i < end; i++) {
          assert(items[i] != null);
          _validate(items[i], instance[i]);
        }
        if (additionalItems is Schema) {
          for (int i = end; i < actual; i++) {
            _validate(additionalItems, instance[i]);
          }
        } else if (additionalItems is bool) {
          if (!additionalItems && actual > end) {
            _err("${schema._path}: additionalItems false");
          }
        }
      }
    }

    var maxItems = schema._maxItems;
    var minItems = schema._minItems;
    if (maxItems is int && actual > maxItems) {
      _err("${schema._path}: maxItems exceeded ($actual vs $maxItems)");
    } else if (schema._minItems is int && actual < schema._minItems) {
      _err("${schema._path}: minItems violated ($actual vs $minItems)");
    }

    if (schema._uniqueItems) {
      int end = instance.length;
      int penultimate = end - 1;
      for (int i = 0; i < penultimate; i++) {
        for (int j = i + 1; j < end; j++) {
          if (_jsonEqual(instance[i], instance[j])) {
            _err("${schema._path}: uniqueItems violated: $instance [$i]==[$j]");
          }
        }
      }
    }
  }

  void _validateAllOf(Schema schema, instance) {
    List<Schema> schemas = schema._allOf;
    int errorsSoFar = _errors.length;
    int i = 0;
    schemas.every((s) {
      assert(s != null);
      _validate(s, instance);
      bool valid = _errors.length == errorsSoFar;
      if (!valid) {
        _err("${s._path}/$i: allOf violated ${instance}");
      }
      i++;
      return valid;
    });
  }

  void _validateAnyOf(Schema schema, instance) {
    if (!schema._anyOf.any((s) => new Validator(s).validate(instance))) {
      _err(
          "${schema._path}/anyOf: anyOf violated ($instance, ${schema._anyOf})");
    }
  }

  void _validateOneOf(Schema schema, instance) {
    try {
      schema._oneOf.singleWhere((s) => new Validator(s).validate(instance));
    } on StateError catch (notOneOf) {
      _err("${schema._path}/oneOf: violated ${notOneOf.message}");
    }
  }

  void _validateNot(Schema schema, instance) {
    if (new Validator(schema._notSchema).validate(instance)) {
      _err("${schema._notSchema._path}: not violated");
    }
  }

  void _validateFormat(Schema schema, instance) {
    switch (schema._format) {
      case 'date-time':
        {
          try {
            DateTime.parse(instance);
          } catch (e) {
            _err("'date-time' format not accepted $instance");
          }
        }
        break;
      case 'uri':
        {
          var isValid =
              (_uriValidator != null) ? _uriValidator : _defaultUriValidator;

          if (!isValid(instance)) {
            _err("'uri' format not accepted $instance");
          }
        }
        break;
      case 'email':
        {
          var isValid = (_emailValidator != null)
              ? _emailValidator
              : _defaultEmailValidator;

          if (!isValid(instance)) {
            _err("'email' format not accepted $instance");
          }
        }
        break;
      case 'ipv4':
        {
          if (_ipv4Re.firstMatch(instance) == null) {
            _err("'ipv4' format not accepted $instance");
          }
        }
        break;
      case 'ipv6':
        {
          if (_ipv6Re.firstMatch(instance) == null) {
            _err("'ipv6' format not accepted $instance");
          }
        }
        break;
      case 'hostname':
        {
          if (_hostnameRe.firstMatch(instance) == null) {
            _err("'hostname' format not accepted $instance");
          }
        }
        break;
      default:
        {
          _err("${schema._format} not supported as format");
        }
    }
  }

  void _objectPropertyValidation(Schema schema, Map instance) {
    bool propMustValidate =
        schema._additionalProperties != null && !schema._additionalProperties;

    instance.forEach((k, v) {
      bool propCovered = false;
      Schema propSchema = schema._properties[k];
      if (propSchema != null) {
        assert(propSchema != null);
        _validate(propSchema, v);
        propCovered = true;
      }

      schema._patternProperties.forEach((regex, patternSchema) {
        if (regex.hasMatch(k)) {
          assert(patternSchema != null);
          _validate(patternSchema, v);
          propCovered = true;
        }
      });

      if (!propCovered) {
        if (schema._additionalPropertiesSchema != null) {
          _validate(schema._additionalPropertiesSchema, v);
        } else if (propMustValidate) {
          _err("${schema._path}: unallowed additional property $k");
        }
      }
    });
  }

  void _propertyDependenciesValidation(Schema schema, Map instance) {
    schema._propertyDependencies.forEach((k, dependencies) {
      if (instance.containsKey(k)) {
        if (!dependencies.every((prop) => instance.containsKey(prop))) {
          _err("${schema._path}: prop $k => $dependencies required");
        }
      }
    });
  }

  void _schemaDependenciesValidation(Schema schema, Map instance) {
    schema._schemaDependencies.forEach((k, otherSchema) {
      if (instance.containsKey(k)) {
        if (!new Validator(otherSchema).validate(instance)) {
          _err("${otherSchema._path}: prop $k violated schema dependency");
        }
      }
    });
  }

  void _objectValidation(Schema schema, Map instance) {
    int numProps = instance.length;
    int minProps = schema._minProperties;
    int maxProps = schema._maxProperties;
    if (numProps < minProps) {
      _err(
          "${schema._path}: minProperties violated (${numProps} < ${minProps})");
    } else if (maxProps != null && numProps > maxProps) {
      _err(
          "${schema._path}: maxProperties violated (${numProps} > ${maxProps})");
    }
    if (schema._requiredProperties != null) {
      schema._requiredProperties.forEach((prop) {
        if (!instance.containsKey(prop)) {
          _err(
              "${schema._path}: required prop missing: ${prop} from $instance");
        }
      });
    }
    _objectPropertyValidation(schema, instance);

    if (schema._propertyDependencies != null)
      _propertyDependenciesValidation(schema, instance);

    if (schema._schemaDependencies != null)
      _schemaDependenciesValidation(schema, instance);
  }

  void _validate(Schema schema, dynamic instance) {
    _typeValidation(schema, instance);
    _enumValidation(schema, instance);
    if (instance is List) _itemsValidation(schema, instance);
    if (instance is String) _stringValidation(schema, instance);
    if (instance is num) _numberValidation(schema, instance);
    if (schema._allOf.length > 0) _validateAllOf(schema, instance);
    if (schema._anyOf.length > 0) _validateAnyOf(schema, instance);
    if (schema._oneOf.length > 0) _validateOneOf(schema, instance);
    if (schema._notSchema != null) _validateNot(schema, instance);
    if (schema._format != null) _validateFormat(schema, instance);
    if (instance is Map) _objectValidation(schema, instance);
  }

  void _err(String msg) {
    _logger.warning(msg);
    _errors.add(msg);
    if (!_reportMultipleErrors) throw new FormatException(msg);
  }

  // end <class Validator>

  Schema _rootSchema;
  List<String> _errors = [];
  bool _reportMultipleErrors;
}

// custom <part validator>
// end <part validator>

RegExp _emailRe = new RegExp(r'^[_A-Za-z0-9-\+]+(\.[_A-Za-z0-9-]+)*'
    r'@'
    r'[A-Za-z0-9-]+(\.[A-Za-z0-9]+)*(\.[A-Za-z]{2,})$');
var _defaultEmailValidator =
    (String email) => _emailRe.firstMatch(email) != null;
var _emailValidator = _defaultEmailValidator;
RegExp _ipv4Re = new RegExp(r'^(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.'
    r'(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.'
    r'(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.'
    r'(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))$');
RegExp _ipv6Re = new RegExp(r'(^([0-9a-f]{1,4}:){1,1}(:[0-9a-f]{1,4}){1,6}$)|'
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
    r'(^:(:[0-9a-f]{1,4}){1,5}:(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}$)');
var _defaultUriValidator = (String uri) {
  try {
    final result = Uri.parse(uri);
    if (result.path.startsWith('//')) return false;
    return true;
  } catch (e) {
    return false;
  }
};
RegExp _hostnameRe = new RegExp(r'^(?=.{1,255}$)'
    r'[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?'
    r'(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$');
var _uriValidator = _defaultUriValidator;
