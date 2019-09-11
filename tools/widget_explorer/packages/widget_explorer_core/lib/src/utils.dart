// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

/// Gets the [ElementAnnotation] object representing the annotation with the
/// given class name. (e.g., `ExampleValue`, `Generator`)
ElementAnnotation getAnnotationWithName(Element element, String name) {
  if (element == null || element.metadata == null) {
    return null;
  }

  for (ElementAnnotation annotation in element.metadata) {
    DartObject annotationValue = annotation.computeConstantValue();
    if (annotationValue?.type?.name == name) {
      return annotation;
    }
  }

  return null;
}

/// Converts an UpperCase camelized string into a lowerCase camelized string.
String lowerCamelize(String str) {
  if (str == null || str == '') {
    return str;
  }

  return '${str.substring(0, 1).toLowerCase()}${str.substring(1)}';
}
