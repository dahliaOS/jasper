// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:widgets_meta/widgets_meta.dart';

import 'example_video_id.dart';

/// Duration between switching thumbnails to fake video playing effect
final Duration _kSlideDuration = const Duration(milliseconds: 300);

/// Duration after which the Play Overlay will autohide
final Duration _kOverlayAutoHideDuration = const Duration(seconds: 1);

/// UI Widget that can "play" Youtube videos.
///
/// Since there is no video support for Flutter, this widget just shows a
/// slideshow of thumbnails for the video.
class YoutubePlayer extends StatefulWidget {
  /// ID for given youtube video
  final String videoId;

  /// Youtube API key needed to access the Youtube Public APIs
  final String apiKey;

  /// Constructor
  YoutubePlayer({
    Key key,
    @required @ExampleValue(kExampleVideoId) this.videoId,
    @required @ConfigKey('google_api_key') this.apiKey,
  })
      : super(key: key) {
    assert(videoId != null);
    assert(apiKey != null);
  }

  @override
  _YoutubePlayerState createState() => new _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer> {
  /// Key to hold reference to slideshow state so the player can pause/play
  final GlobalKey<_YoutubeSlideShowState> _slideShowKey =
      new GlobalKey<_YoutubeSlideShowState>();

  /// Flag for whether the video is playing or not
  bool _playing = false;

  /// Flag for whether the play-button overlay is showing on top of the video
  bool _showingPlayOverlay = true;

  /// Track the current thumbnail that is being shown
  /// Youtube provides 4 thumbnails (0,1,2,3)
  final int _thumbnailIndex = 0;

  /// Show the play-button overlay on top of the video
  /// The play overlay will auto-hide after 1 second if the video is currently
  /// playing.
  void _showPlayOverlay() {
    setState(() {
      _showingPlayOverlay = true;
    });
    new Timer(_kOverlayAutoHideDuration, () {
      if (mounted) {
        setState(() {
          if (_playing) {
            _showingPlayOverlay = false;
          }
        });
      }
    });
  }

  /// Toggle between playing and pausing depending on the current state
  void _togglePlay() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _slideShowKey.currentState.play();
        _showingPlayOverlay = false;
      } else {
        _slideShowKey.currentState.pause();
      }
    });
  }

  /// Overlay widget that contains playback controls
  Widget _buildControlOverlay() {
    return new Container(
      decoration: new BoxDecoration(
        gradient: new RadialGradient(
          center: FractionalOffset.center,
          colors: <Color>[
            const Color.fromARGB(30, 0, 0, 0),
            const Color.fromARGB(200, 0, 0, 0),
            const Color.fromARGB(200, 0, 0, 0),
          ],
          stops: <double>[
            0.0,
            0.7,
            1.0,
          ],
          radius: 1.0,
        ),
      ),
      child: new Material(
        color: const Color.fromRGBO(0, 0, 0, 0.0),
        child: new Center(
          child: new IconButton(
            icon: _playing ? new Icon(Icons.pause) : new Icon(Icons.play_arrow),
            iconSize: 60.0,
            onPressed: _togglePlay,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      // TODO(dayang): Preserve video aspect ration for different device sizes
      // https://fuchsia.atlassian.net/browse/SO-117
      height: 250.0,
      child: new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          new InkWell(
            onTap: _showPlayOverlay,
            child: new _YoutubeSlideShow(
              key: _slideShowKey,
              videoId: widget.videoId,
            ),
          ),
          new Offstage(
            offstage: !_showingPlayOverlay,
            child: _buildControlOverlay(),
          ),
        ],
      ),
    );
  }
}

/// UI widget that shows a slideshow of thumbnails for a given youtube video
class _YoutubeSlideShow extends StatefulWidget {
  /// ID for given youtube video
  final String videoId;

  /// Constructor
  _YoutubeSlideShow({
    Key key,
    @required this.videoId,
  })
      : super(key: key) {
    assert(videoId != null);
  }

  @override
  _YoutubeSlideShowState createState() => new _YoutubeSlideShowState();
}

class _YoutubeSlideShowState extends State<_YoutubeSlideShow> {
  /// Track the current thumbnail that is being shown
  /// Youtube provides 4 thumbnails (0,1,2,3)
  int _thumbnailIndex = 0;

  /// Track the current timer showing the slideshow
  Timer _currentTimer;

  String get _currentThumbnailURL =>
      'http://img.youtube.com/vi/${widget.videoId}/$_thumbnailIndex.jpg';

  /// "Pause" the video by stopping the slideshow
  void pause() {
    _currentTimer?.cancel();
  }

  /// "Play" the video by starting the slideshow
  void play() {
    _currentTimer = new Timer.periodic(_kSlideDuration, (Timer timer) {
      if (mounted) {
        setState(() {
          if (_thumbnailIndex == 3) {
            _thumbnailIndex = 0;
          } else {
            _thumbnailIndex++;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _currentTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new Image.network(
      _currentThumbnailURL,
      gaplessPlayback: true,
      fit: BoxFit.cover,
    );
  }
}
