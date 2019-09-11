// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixtures/fixtures.dart';
import 'package:uuid/uuid.dart';

import 'user.dart';

export 'package:fixtures/fixtures.dart';

/// Model specific [Fixtures], extending in this way prevents circular
/// dependencies in the BUILD.gn files.
class ModelFixtures extends Fixtures {
  static final String _uuidUser =
      Fixtures.uuid.v5(Uuid.NAMESPACE_URL, namespace('users'));

  /// Generate a [User].
  ///
  /// Generate a random [User]:
  ///
  ///     User user = fixtures.user();
  ///
  /// Generate a [User] with a specific name:
  ///
  ///     User user = fixtures.user(name: 'Alice');
  ///
  User user({String name, String email}) {
    name ??= this.name(name);
    email ??= 'user-${sequence(email)}@example.org';

    String id = Fixtures.uuid.v5(_uuidUser, email);
    return new User(
      id: id,
      name: name,
      email: email,
      locale: 'en',
    );
  }
}
