// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_search_api/google_search_api.dart';
import 'package:lib.widgets/hacks.dart';
import 'package:meta/meta.dart';

import 'image_picker.dart';

const Duration _kSearchDelay = const Duration(milliseconds: 1000);

/// Wrapper around a [ImagePicker] that uses Google Custom Search to populate
/// images based on a given query.
///
/// Requires a valid Google API key and a Custom Search ID:
/// https://developers.google.com/custom-search/
class GoogleSearchImagePicker extends StatefulWidget {
  /// API key used for a Custom Google Search
  final String apiKey;

  /// ID of the Custom Google Search instance
  final String customSearchId;

  /// Optional initial image search query
  final String query;

  /// Optional list of initial list of selected image urls.
  final List<String> initialSelection;

  /// Callback that is fired when the set of selected images is changed
  final ImageSelectCallback onSelectionChanged;

  /// Callback that is fired when the user has completed selecting all the
  /// images and wants to "add them"
  final ImageSelectCallback onAdd;

  /// Constructor
  GoogleSearchImagePicker({
    Key key,
    @required this.apiKey,
    @required this.customSearchId,
    this.query,
    this.initialSelection,
    this.onSelectionChanged,
    this.onAdd,
  })
      : super(key: key) {
    assert(apiKey != null);
    assert(customSearchId != null);
  }

  @override
  _GoogleSearchImagePickerState createState() =>
      new _GoogleSearchImagePickerState();
}

class _GoogleSearchImagePickerState extends State<GoogleSearchImagePicker> {
  List<String> _sourceImages = <String>[];
  String _lastInputValue;
  TextEditingController _controller;
  bool _isLoading = false;
  Timer _timer;
  String _lastSearchQuery;
  List<String> _initialSelection;
  // Give a Google query a "count" so that a slower query doesn't overwrite
  // a later query that resolves faster.
  int _counter = 0;

  void _handleInputChange(String value) {
    setState(() {
      // Only call a Google Search query if the text has changed.
      // For example onChanged for an TextField will fire for cursor events.
      if (value != _lastInputValue) {
        _setTimer();
      }
      _lastInputValue = value;
    });
  }

  // Sets a delay so that we don't make search queries for consecutive
  // keystrokes.
  void _setTimer() {
    _timer?.cancel();
    _timer = new Timer(_kSearchDelay, () => _search(_controller.text, null));
  }

  bool get _hideEmptyState =>
      _isLoading || _sourceImages.isNotEmpty || _controller.text.isNotEmpty;

  Future<Null> _search(String query, List<String> initialSelection) async {
    if (query == _lastSearchQuery) {
      return null;
    }
    if (query.isEmpty) {
      setState(() {
        _sourceImages = <String>[];
      });
    } else {
      _counter++;
      int currentCount = _counter;
      setState(() {
        _isLoading = true;
      });
      List<String> images = await GoogleSearchAPI.images(
        query: query,
        apiKey: widget.apiKey,
        customSearchId: widget.customSearchId,
      );
      if (currentCount == _counter) {
        setState(() {
          _lastSearchQuery = query;
          _sourceImages = images;
          _initialSelection = initialSelection;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = new TextEditingController(text: widget.query);
    _lastInputValue = _controller.text;

    if (widget.query != null && widget.query.isNotEmpty) {
      _search(widget.query, widget.initialSelection);
    }
  }

  @override
  void didUpdateWidget(GoogleSearchImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Make a new search if widget.query has been changed
    if (oldWidget.query != widget.query ||
        !const ListEquality<String>()
            .equals(oldWidget.initialSelection, widget.initialSelection)) {
      if (oldWidget.query ?? '' == _controller.text) {
        _controller.text = widget.query ?? '';
        _search(widget.query, widget.initialSelection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Widget searchInput = new Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 4.0),
      decoration: new BoxDecoration(
        border: new Border(
          bottom: new BorderSide(
            color: Colors.grey[300],
          ),
        ),
      ),
      child: new Row(
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: new Icon(
              Icons.search,
              color: theme.primaryColor,
            ),
          ),
          new Expanded(
            child: new FuchsiaCompatibleTextField(
              controller: _controller,
              onChanged: _handleInputChange,
              decoration: new InputDecoration.collapsed(
                hintText: 'search images',
              ),
            ),
          ),
        ],
      ),
    );
    Widget loadingOverlay = new Positioned.fill(
      child: new Offstage(
        offstage: !_isLoading,
        child: new Material(
          color: Colors.white.withAlpha(100),
          child: new Center(
            child: new CircularProgressIndicator(
              value: null,
              valueColor: new AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
        ),
      ),
    );
    Widget emptyState = new Positioned.fill(
      child: new AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget child) {
          // _hideEmptyState depends on _controller.text, which means we need to
          // listen to _controller to make sure we rebuild this widget when
          // _controller.text changes.
          return new Offstage(
            offstage: _hideEmptyState,
            child: child,
          );
        },
        child: new Material(
          color: Colors.white,
          child: new Center(
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new Icon(
                  Icons.image,
                  color: Colors.grey[400],
                  size: 56.0,
                ),
                new Text(
                  'type to search for images',
                  style: new TextStyle(
                    fontSize: 20.0,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        searchInput,
        new Expanded(
          child: new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              new ImagePicker(
                imageUrls: _sourceImages,
                initialSelection: _initialSelection,
                onSelectionChanged: widget.onSelectionChanged,
                onAdd: widget.onAdd,
              ),
              loadingOverlay,
              emptyState,
            ],
          ),
        ),
      ],
    );
  }
}
