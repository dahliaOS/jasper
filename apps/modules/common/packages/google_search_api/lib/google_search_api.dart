// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:http/http.dart' as http;

const String _kApiBaseUrl = 'www.googleapis.com';

/// Client to retreive Google search data
class GoogleSearchAPI {
  /// Perform a Google image search for a given query string
  static Future<List<String>> images({
    String query,
    String apiKey,
    String customSearchId,
  }) async {
    Map<String, String> queryParams = new Map<String, String>();
    queryParams['q'] = query;
    queryParams['key'] = apiKey;
    queryParams['cx'] = customSearchId;
    queryParams['searchType'] = 'image';
    queryParams['num'] = '10';
    Uri uri = new Uri.https(_kApiBaseUrl, '/customsearch/v1', queryParams);
    http.Response response = await http.get(uri);
    if (response.statusCode != 200) {
      return null;
    }
    dynamic results = json.decode(response.body);
    return results['items']
        .map((dynamic item) => item['image']['thumbnailLink'])
        .toList();
  }
}
