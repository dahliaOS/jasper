// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

enum Output {
  // Rewrite the prompt line, including text entered by the user.
  prompt,

  // Tell the user they did something illegal.
  bell,

  // Evaluate a Dart expression and print the result.
  evaluate,
}

// Interact with the user on the command line, by converting input strings
// into output events.
Stream<List<dynamic>> interact(Stream<String> inputs) async* {
  var history = <String>[];
  var historyAt = 0;

  var line = '';
  var cursorAt = 0;

  List<dynamic> getPrompt() {
    return [Output.prompt, line, cursorAt];
  }

  await for (var input in inputs) {
    if (input == '\u{7f}') {
      // Delete
      if (cursorAt == 0) {
        yield [Output.bell];
      } else {
        line = line.substring(0, cursorAt - 1) + line.substring(cursorAt);
        cursorAt--;
        yield getPrompt();
      }
    } else if (input == '\u{1b}[A') {
      // Up
      if (historyAt == 0) {
        yield [Output.bell];
      } else {
        historyAt--;
        line = history[historyAt];
        cursorAt = line.length;
        yield getPrompt();
      }
    } else if (input == '\u{1b}[B') {
      // Down
      if (historyAt >= history.length - 1) {
        yield [Output.bell];
      } else {
        historyAt++;
        line = history[historyAt];
        cursorAt = line.length;
        yield getPrompt();
      }
    } else if (input == '\u{1b}[C') {
      // Forward
      if (cursorAt == line.length) {
        yield [Output.bell];
      } else {
        cursorAt++;
        yield getPrompt();
      }
    } else if (input == '\u{1b}[D') {
      // Back
      if (cursorAt == 0) {
        yield [Output.bell];
      } else {
        cursorAt--;
        yield getPrompt();
      }
    } else {
      var buffer = StringBuffer();
      for (var rune in input.runes) {
        if (rune > 127) {
          // Substitute unicode literals in ASCII, so that we don't have to
          // figure out characters' display width when moving the cursor.
          var hex = rune.toRadixString(16);
          buffer.write('\\u{$hex}');
        } else if (rune == 10) {
          // New line
          line += buffer.toString();
          buffer.clear();
          yield [Output.evaluate, line];
          history.add(line);
          historyAt = history.length;
          line = '';
          cursorAt = 0;
        } else {
          buffer.writeCharCode(rune);
        }
      }

      if (buffer.isNotEmpty) {
        line =
            line.substring(0, cursorAt) +
            buffer.toString() +
            line.substring(cursorAt);
        cursorAt += buffer.length;
        yield getPrompt();
      }
    }
  }
}
