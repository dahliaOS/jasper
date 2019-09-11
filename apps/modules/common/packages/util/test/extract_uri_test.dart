// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:util/extract_uri.dart';

void main() {
  test('extractURI("...")', () {
    String text = 'Checkout these videos!\n'
        'https://www.youtube.com/watch?v=p8OgWPcNA6o\n'
        'https://www.youtube.com/watch?v=ZAn3JdtSrnY';
    List<Uri> uris = extractURI(text);

    expect(
        uris.contains(Uri.parse('https://www.youtube.com/watch?v=ZAn3JdtSrnY')),
        isTrue);
    expect(
        uris.contains(Uri.parse('https://www.youtube.com/watch?v=p8OgWPcNA6o')),
        isTrue);
  });
}
