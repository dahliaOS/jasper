// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:test/test.dart';

import 'package:repl/interact.dart';

void main() {
  const delete = '\u{7f}';
  const up = '\u{1b}[A';
  const down = '\u{1b}[B';
  const forward = '\u{1b}[C';
  const back = '\u{1b}[D';

  test('write and delete', () {
    expect(interact(Stream.fromIterable([
      '1', '2', '3',
      delete, delete, delete, delete,
    ])), emitsInOrder([
      [Output.prompt, '1', 1],
      [Output.prompt, '12', 2],
      [Output.prompt, '123', 3],
      [Output.prompt, '12', 2],
      [Output.prompt, '1', 1],
      [Output.prompt, '', 0],
      [Output.bell],
    ]));
  });

  test('delete from middle and check boundaries', () {
    expect(interact(Stream.fromIterable([
      '1', '2', '3',
      back, delete,
      back, back,
      forward, forward, forward,
      back,
    ])), emitsInOrder([
      [Output.prompt, '1', 1],
      [Output.prompt, '12', 2],
      [Output.prompt, '123', 3],
      [Output.prompt, '123', 2],
      [Output.prompt, '13', 1],
      [Output.prompt, '13', 0],
      [Output.bell],
      [Output.prompt, '13', 1],
      [Output.prompt, '13', 2],
      [Output.bell],
      [Output.prompt, '13', 1],
    ]));
  });

  test('history', () {
    expect(interact(Stream.fromIterable([
      '1', '\n', '2', '\n',
      up, up, up,
      down, down,
      back, '-', '\n',
      up, up,
    ])), emitsInOrder([
      [Output.prompt, '1', 1],
      [Output.evaluate, '1'],
      [Output.prompt, '2', 1],
      [Output.evaluate, '2'],
      [Output.prompt, '2', 1],
      [Output.prompt, '1', 1],
      [Output.bell],
      [Output.prompt, '2', 1],
      [Output.bell],
      [Output.prompt, '2', 0],
      [Output.prompt, '-2', 1],
      [Output.evaluate, '-2'],
      [Output.prompt, '-2', 2],
      [Output.prompt, '2', 1],
    ]));
  });

  test('unicode literal', () {
    expect(interact(Stream.fromIterable([
      '1', back, '🐙',
    ])), emitsInOrder([
      [Output.prompt, '1', 1],
      [Output.prompt, '1', 0],
      [Output.prompt, '\\u{1f419}1', 9],
    ]));
  });

  test('paste', () {
    expect(interact(Stream.fromIterable([
      '123',
    ])), emitsInOrder([
      [Output.prompt, '123', 3],
    ]));
  });

  test('multi-line paste', () {
    expect(interact(Stream.fromIterable([
      '1', '2\n34\n5',
      up, up,
    ])), emitsInOrder([
      [Output.prompt, '1', 1],
      [Output.evaluate, '12'],
      [Output.evaluate, '34'],
      [Output.prompt, '5', 1],
      [Output.prompt, '34', 2],
      [Output.prompt, '12', 2],
    ]));
  });
}
