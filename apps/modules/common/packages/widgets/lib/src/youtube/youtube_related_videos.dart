// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:models/youtube.dart';
import 'package:widgets_meta/widgets_meta.dart';

import 'example_video_id.dart';
import 'loading_state.dart';
import 'youtube_thumbnail.dart';

const String _kApiBaseUrl = 'content.googleapis.com';

const String _kApiRestOfUrl = '/youtube/v3/search';

const String _kMaxResults = '10';

/// UI widget that loads and shows related videos for a given Youtube video
class YoutubeRelatedVideos extends StatefulWidget {
  /// ID of youtube video to show related videos for
  final String videoId;

  /// Youtube API key needed to access the Youtube Public APIs
  final String apiKey;

  /// Constructor
  YoutubeRelatedVideos({
    Key key,
    @required @ExampleValue(kExampleVideoId) this.videoId,
    @required @ConfigKey('google_api_key') this.apiKey,
  }) : super(key: key) {
    assert(videoId != null);
    assert(apiKey != null);
  }

  @override
  _YoutubeRelatedVideosState createState() => new _YoutubeRelatedVideosState();
}

class _YoutubeRelatedVideosState extends State<YoutubeRelatedVideos> {
  /// List of related videos to render
  List<VideoData> _relatedVideos;

  /// Loading State
  LoadingState _loadingState = LoadingState.inProgress;

  @override
  void initState() {
    super.initState();
    _getRelatedVideoData(
      videoId: widget.videoId,
      apiKey: widget.apiKey,
    ).then((List<VideoData> videos) {
      if (mounted) {
        if (videos == null) {
          setState(() {
            _loadingState = LoadingState.failed;
          });
        } else {
          setState(() {
            _loadingState = LoadingState.completed;
            _relatedVideos = videos;
          });
        }
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _loadingState = LoadingState.failed;
        });
      }
    });
  }

  Widget _buildVideoPreview(VideoData videoData) {
    return new Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            width: 200.0,
            height: 110.0,
            child: new YoutubeThumbnail(videoId: videoData.id),
          ),
          new Expanded(
            flex: 1,
            child: new Container(
              padding: const EdgeInsets.only(left: 16.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: new Text(
                      videoData.title,
                      style: new TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  new Container(
                    margin: const EdgeInsets.only(bottom: 4.0),
                    child: new Text(
                      videoData.channelTitle,
                      style: new TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  new Text(
                    new DateFormat.yMMMMd().format(videoData.publishedAt),
                    style: new TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget videoList;
    switch (_loadingState) {
      case LoadingState.inProgress:
        videoList = new Container(
          height: 100.0,
          child: new Center(
            child: new CircularProgressIndicator(
              value: null,
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.grey[300]),
            ),
          ),
        );
        break;
      case LoadingState.completed:
        videoList = new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _relatedVideos.map((VideoData videoData) {
            return _buildVideoPreview(videoData);
          }).toList(),
        );
        break;
      case LoadingState.failed:
        videoList = new Container(
          height: 100.0,
          child: new Text('Content Failed to Load'),
        );
        break;
    }
    return videoList;
  }
}

/// Calls Youtube API to retrieve related videos for given videoId
/// TODO(dayang): Use googleapis package
Future<List<VideoData>> _getRelatedVideoData({
  String videoId,
  String apiKey,
}) async {
  Map<String, String> params = <String, String>{
    'part': 'snippet',
    'relatedToVideoId': videoId,
    'maxResults': _kMaxResults,
    'type': 'video',
    'key': apiKey,
  };

  Uri uri = new Uri.https(_kApiBaseUrl, _kApiRestOfUrl, params);
  http.Response response = await http.get(uri);
  if (response.statusCode != 200) {
    return null;
  }

  dynamic jsonData = json.decode(response.body);

  if (jsonData['items'] is List<Map<String, dynamic>>) {
    return jsonData['items'].map((dynamic json) {
      return new VideoData.fromJson(json);
    }).toList();
  }
  return null;
}
