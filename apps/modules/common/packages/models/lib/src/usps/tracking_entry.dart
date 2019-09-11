// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:xml/xml.dart' as xml;

/// Represents a single tracking entry for a USPS package
class TrackingEntry {
  /// Text representation of time when entry was recorded
  /// eg. "10:31 am"
  final String time;

  /// Text representation of day when entry was recorded
  /// eg. "November 5, 2016"
  final String date;

  /// City where tracking entry is recorded
  final String city;

  /// State where tracking entry is recorded
  final String state;

  /// Zipcode where tracking entry is recorded
  final String zipCode;

  /// Details of tracking entry
  /// eg. "Picked Up by Shipping Partner"
  final String entryDetails;

  /// Constructor
  TrackingEntry({
    String time,
    String date,
    String city,
    String state,
    String zipCode,
    String entryDetails,
  })
      : this.time = time ?? '',
        this.date = date ?? '',
        this.city = city ?? '',
        this.state = state ?? '',
        this.zipCode = zipCode ?? '',
        this.entryDetails = entryDetails ?? '';

  /// Creates a TrackingEntry from XML data
  factory TrackingEntry.fromXML(xml.XmlNode xmlNode) {
    String time;
    String date;
    String city;
    String state;
    String zipCode;
    String entryDetails;
    xmlNode.children.forEach((xml.XmlNode childNode) {
      // XML tag/name data can only be retrieved from a XmlElement
      // We must first cast try to cast the node to a element
      xml.XmlElement xmlElement;
      if (childNode is xml.XmlElement) {
        xmlElement = childNode;
        switch (xmlElement.name.toString()) {
          case 'Event':
            entryDetails = xmlElement.text;
            break;
          case 'EventCity':
            city = xmlElement.text;
            break;
          case 'EventState':
            state = xmlElement.text;
            break;
          case 'EventZIPCode':
            zipCode = xmlElement.text;
            break;
          case 'EventDate':
            date = xmlElement.text;
            break;
          case 'EventTime':
            time = xmlElement.text;
            break;
        }
      }
    });
    return new TrackingEntry(
      time: time,
      date: date,
      city: city,
      state: state,
      zipCode: zipCode,
      entryDetails: entryDetails,
    );
  }

  /// Full string representation of location for tracking entry
  String get fullLocation => '$city, $zipCode, $state';
}
