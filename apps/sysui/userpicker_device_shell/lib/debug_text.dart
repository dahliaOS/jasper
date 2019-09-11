// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Displays debug text like hostname and ip addresses.
class DebugText extends StatefulWidget {
  /// Called when network information is shown.
  final VoidCallback onShowNetwork;

  /// Constructor.
  DebugText({this.onShowNetwork});

  @override
  _DebugTextState createState() => new _DebugTextState();
}

class _DebugTextState extends State<DebugText> {
  final List<InternetAddress> _addresses = <InternetAddress>[];
  int _dataSize;
  bool _networkingReady;
  bool _showHostInformation = true;
  bool _showNetworkingInformation = false;
  @override
  void initState() {
    super.initState();
    new Timer(
      const Duration(minutes: 1),
      () => setState(() {
            _showHostInformation = false;
          }),
    );

    /// TODO(apwilson): Remove this delay when NET-79 is fixed.
    new Timer(const Duration(seconds: 10), _checkNetworking);

    new Timer(
      const Duration(seconds: 11),
      () => setState(() {
            _showNetworkingInformation = true;
            widget.onShowNetwork?.call();
          }),
    );

    /// TODO(apwilson): Reenable this code when it doesn't blow the app up.
    /*
    NetworkInterface.list().then((List<NetworkInterface> interfaces) {
      if (!mounted) {
        return;
      }
      setState(() {
        interfaces.forEach((NetworkInterface networkInterface) {
          _addresses.addAll(networkInterface.addresses);
        });
      });
    });
    */

    _checkData();
  }

  void _checkData() {
    new Directory('/data').stat().then((FileStat stat) {
      setState(() {
        if (!mounted) {
          return;
        }
        _dataSize = stat.size;
        if (_dataSize == 0) {
          new Timer(const Duration(seconds: 5), _checkData);
        }
      });
    }).catchError((_, __) {
      new Timer(const Duration(seconds: 5), _checkData);
    });
  }

  void _checkNetworking() {
    http.get('http://www.example.com').then((http.Response response) {
      setState(() {
        if (!mounted) {
          return;
        }
        _networkingReady = response.statusCode == 200;
        if (!_networkingReady) {
          new Timer(const Duration(seconds: 5), _checkNetworking);
        }
      });
    }).catchError((_, __) {
      new Timer(const Duration(seconds: 5), _checkNetworking);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<_DebugEntry> columnChildren = <_DebugEntry>[];
    if (_showNetworkingInformation && _showHostInformation) {
      columnChildren.add(new _DebugEntry(text: Platform.localHostname));
      columnChildren.addAll(
        _addresses
            .map(
              (InternetAddress address) =>
                  new _DebugEntry(text: address.address),
            )
            .toList(),
      );
    }
    if (!_showNetworkingInformation) {
      columnChildren.add(
        new _DebugEntry(
          text: 'Delaying network check due to NET-79...',
          color: Colors.yellow,
        ),
      );
    } else if (_networkingReady != true) {
      columnChildren.add(
        new _DebugEntry(
          text: 'Networking is NOT ready!',
          color: Colors.redAccent,
        ),
      );
    }
    if (_dataSize == null) {
      columnChildren.add(
        new _DebugEntry(text: 'Data is NOT ready!', color: Colors.yellow),
      );
    } else if (_dataSize == 0) {
      columnChildren.add(
        new _DebugEntry(
          text: 'Data is NOT persistent!',
          color: Colors.redAccent,
        ),
      );
    }
    return new Offstage(
      offstage: columnChildren.isEmpty,
      child: new Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.black54,
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: new List<Widget>.generate(
            columnChildren.length,
            (int i) => new Container(
                  padding: new EdgeInsets.only(top: (i == 0) ? 0.0 : 8.0),
                  child: new Text(
                    columnChildren[i].text,
                    style: new TextStyle(
                      fontFamily: 'RobotoMono',
                      color: columnChildren[i].color,
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _DebugEntry {
  final Color color;
  final String text;
  _DebugEntry({this.text, this.color: Colors.white});
}
