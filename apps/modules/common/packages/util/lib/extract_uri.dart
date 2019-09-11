// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

Uri _mapper(Match match) {
  String url = match.group(0);
  return Uri.parse(url);
}

/// Extract a [List] of unique URIs from a string.
List<Uri> extractURI(String string) {
  String pattern = r'(?:https?)(?:\S+)';
  RegExp exp = new RegExp(pattern, multiLine: false, caseSensitive: false);
  return new List<Uri>.from(exp.allMatches(string).map(_mapper));
}
