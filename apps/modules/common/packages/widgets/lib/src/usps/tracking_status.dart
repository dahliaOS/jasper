// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:models/usps.dart';
import 'package:widgets_meta/widgets_meta.dart';
import 'package:xml/xml.dart' as xml;

import '../common/embedded_child.dart';

final String _kApiBaseUrl = 'production.shippingapis.com';

final String _kApiRestOfUrl = 'ShippingApi.dll';

const double _kMapHeight = 200.0;

/// Callback function signature for selecting a location to focus on
typedef void LocationSelectCallback(String location);

/// Represents the state of data loading
enum LoadingState {
  /// Still fetching data
  inProgress,

  /// Data has completed loading
  completed,

  /// Data failed to load
  failed,
}

/// UI Widget that tenders USPS tracking information for given package
class TrackingStatus extends StatefulWidget {
  /// API key for USPS APIs
  final String apiKey;

  /// USPS tracking code for given package
  final String trackingCode;

  /// Callback for selecting a location
  final LocationSelectCallback onLocationSelect;

  /// Constructor
  TrackingStatus({
    Key key,
    @required @ConfigKey('usps_api_key') this.apiKey,
    @required @ExampleValue('9374889676090175041871') this.trackingCode,
    this.onLocationSelect,
  })
      : super(key: key) {
    assert(apiKey != null);
    assert(trackingCode != null);
  }

  @override
  _TrackingStatusState createState() => new _TrackingStatusState();
}

class _TrackingStatusState extends State<TrackingStatus> {
  /// Tracking Entries retrieved from the USPS API
  List<TrackingEntry> _trackingEntries;

  TrackingEntry _selectedEntry;

  /// Loading State for Tracking Data
  LoadingState _loadingState = LoadingState.inProgress;

  EmbeddedChild _embeddedMap;

  /// Make request to USPS API to retrieve tracking data for given tracking code
  Future<List<TrackingEntry>> _getTrackingData() async {
    Map<String, String> params = <String, String>{};
    params['API'] = 'TrackV2';
    // Do not use the ''' syntax because the newlines and spaces also get
    // encoded.
    params['XML'] = '<TrackFieldRequest USERID="${widget.apiKey}">'
        '<TrackID ID="${widget.trackingCode}" />'
        '</TrackFieldRequest>';

    Uri uri = new Uri.http(_kApiBaseUrl, _kApiRestOfUrl, params);
    http.Response response = await http.get(uri);
    xml.XmlDocument xmlData = xml.parse(response.body);

    Iterable<xml.XmlElement> topLevelElements =
        xmlData.findAllElements('TrackInfo');
    if (topLevelElements.isNotEmpty) {
      return topLevelElements.first.children
          .map((xml.XmlNode node) => new TrackingEntry.fromXML(node))
          .toList();
    } else {
      return null;
    }
  }

  void _handleEntrySelect(TrackingEntry entry) {
    setState(() {
      _selectedEntry = entry;
    });
    widget.onLocationSelect?.call(entry?.fullLocation);
  }

  // HACK(dayang): Assume the package to be delivered if the phrase "delivered"
  // is in the most recent entry, otherwise assume the package to be en route
  String get _currentOverallStatus {
    if (_trackingEntries.isEmpty) {
      return 'Package En Route';
    }
    if (_trackingEntries.first.entryDetails
        .toLowerCase()
        .contains('delivered')) {
      return 'Package Delivered';
    } else {
      return 'Package En Route';
    }
  }

  @override
  void initState() {
    super.initState();

    _embeddedMap = kEmbeddedChildProvider.buildEmbeddedChild('map', '');
    print('[tracking_status] _embeddedMap: $_embeddedMap');

    _getTrackingData().then((List<TrackingEntry> entries) {
      if (mounted) {
        setState(() {
          if (entries == null) {
            _loadingState = LoadingState.failed;
          } else {
            _loadingState = LoadingState.completed;
            _trackingEntries = entries;
            _handleEntrySelect(entries.first);
          }
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _loadingState = LoadingState.failed;
        });
      }
    });
  }

  @override
  void dispose() {
    _embeddedMap?.dispose();
    super.dispose();
  }

  Widget _buildTrackingEntry(TrackingEntry entry) {
    // HACK(dayang): Flutter border widths are not being respected so I make a
    // background container with some padding on the left to emulate a border
    return new Container(
      padding: const EdgeInsets.only(left: 4.0),
      color: entry == _selectedEntry ? Colors.indigo[500] : Colors.white,
      child: new Material(
        color: Colors.white,
        child: new InkWell(
          onTap: () {
            _handleEntrySelect(entry);
          },
          child: new Container(
            padding: const EdgeInsets.only(
              left: 20.0,
              right: 24.0,
              top: 16.0,
              bottom: 16.0,
            ),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Row(
                  children: <Widget>[
                    new Container(
                      width: 110.0,
                      child: new Text(
                        entry.date,
                        style: new TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    new Text(
                      entry.time,
                      style: new TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                new Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Expanded(
                        flex: 1,
                        child: new Text(
                          '${entry.city}, ${entry.state} ${entry.zipCode}',
                        ),
                      ),
                      new Expanded(
                        flex: 1,
                        child: new Text(entry.entryDetails),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return new Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 16.0,
      ),
      color: Colors.indigo[500],
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          new Text(
            _currentOverallStatus,
            style: new TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
          new Image.network(
            'http://uspsblog.com/wp-content/themes/postalposts/assets/img/icon-logo-transparent@2x.png',
            height: 20.0,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingEntryList(BuildContext context) {
    List<Widget> children = <Widget>[];

    children.add(_buildHeader());

    children.add(new SizedBox(
      height: _kMapHeight,
      child: _embeddedMap.widgetBuilder(context),
    ));

    _trackingEntries.forEach((TrackingEntry entry) {
      children.add(_buildTrackingEntry(entry));
    });

    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget entryList;
    switch (_loadingState) {
      case LoadingState.inProgress:
        entryList = new Container(
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
        entryList = _buildTrackingEntryList(context);
        break;
      case LoadingState.failed:
        entryList = new Container(
          height: 100.0,
          child: new Text('Tracking Data Failed to Load'),
        );
        break;
    }
    return entryList;
  }
}
