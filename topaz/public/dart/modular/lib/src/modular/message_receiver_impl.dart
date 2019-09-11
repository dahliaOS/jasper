// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.component/message_queue.fidl.dart';
import 'package:meta/meta.dart';

/// This is the function type that [MessageReceiverImpl] accepts; messages will
/// be forwarded to this function, along with an [ack] callback that the user
/// must call on receipt of the message. This callback will have the same
/// signature as [MessageReader.onReceive] fidl method (see its documentation
/// for details).
typedef void MessageReceiverCallback(String message, void ack());

/// Helper class for receiving messages on a given message queue.
class MessageReceiverImpl extends MessageReader {
  final MessageReaderBinding _binding = new MessageReaderBinding();
  final MessageReceiverCallback _onReceiveMessage;

  /// Registers to receive messages on the given message queue. The supplied
  /// [_onReceiveMessage] will be called on every new message.
  MessageReceiverImpl({
    @required MessageQueue messageQueue,
    @required MessageReceiverCallback onReceiveMessage,
  })
      : _onReceiveMessage = onReceiveMessage {
    messageQueue.registerReceiver(_binding.wrap(this));
  }

  /// Not public; it simply implements [MessageReader.onReceive].
  @override
  void onReceive(String message, void ack()) {
    _onReceiveMessage?.call(message, ack);
  }

  /// Stops receiving any new messages by closing the underlying [MessageReader]
  /// interface.
  void close() => _binding.close();
}
