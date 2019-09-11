// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:markdown/markdown.dart';

/// Scrapes links in a markdown document.
class LinkScraper {
  /// Extracts links from the given [file].
  Iterable<String> scrape(String file) {
    final List<Node> nodes =
        new Document().parseLines(new File(file).readAsLinesSync());
    final _Visitor visitor = new _Visitor();
    for (Node node in nodes) {
      node.accept(visitor);
    }
    return visitor.links;
  }
}

class _Visitor implements NodeVisitor {
  static const String _key = 'href';

  final Set<String> links = new Set<String>();

  @override
  bool visitElementBefore(Element element) {
    if (element.attributes.containsKey(_key)) {
      links.add(element.attributes[_key]);
    }
    return true;
  }

  @override
  void visitElementAfter(Element element) {}

  @override
  void visitText(Text text) {}
}
