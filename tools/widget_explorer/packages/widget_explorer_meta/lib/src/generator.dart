// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An annotation for specifying a generator for a model class or parameter.
///
/// This can be used for generating a model class instance that is not a
/// primitive type. It is meant to generate a sample model (e.g. email thread,
/// message, user, etc.) to be provided to a widget constructor.
///
/// @Generator annotation takes two parameters:
///  - [Type] [type]: the type of the generator, which would usually
///    be the `Fixtures` class.
///  - [String] [methodName]: the name of the method to be used to generate
///    the target parameter value.
///
/// The @Generator annotation can be placed (1) in front of a model class
/// declaration, or (2) in front of a parameter declaration of a widget
/// constructor.
///
/// Example of (1):
///
///     /// Represents a single Gmail Message
///     @Generator(ModelFixtures, 'message')
///     class Message {
///       ...
///     }
///
/// Example of (2):
///
///     class MessageListItem extends StatelessWidget {
///       final Message message;
///       // ...
///
///       MessageListItem({
///         Key key,
///         @required @Generator(ModelFixtures, 'message') this.message,
///         ...
///       })
///           : super(key: key);
///     }
///
/// In case the @Generator annotation appears in both places, the one on
/// the parameter declaration takes precedence.
///
/// There are a few restrictions of a generator class.
///  - A generator class must have a default constructor.
///  - The method for generating the model instance must not require any
///    parameters. Having optional parameters is fine, as long as none of
///    them are 'required'.
class Generator {
  /// Creates a new instance of [Generator].
  const Generator(this.type, this.methodName);

  /// The type which specifies the method for generating the target model
  /// instance. Typically this would be the `Fixtures` class.
  ///
  /// The generator type must have a default constructor.
  final Type type;

  /// Name of the method to be used to generate the target parameter value.
  ///
  /// The generator method can be either a static method or an instance method.
  /// In any case, the method should not have any required parameters.
  final String methodName;
}
