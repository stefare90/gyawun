import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:gyawun/ytmusic/helpers.dart';
import 'package:http/http.dart';

class YTClient {
  YTClient() {
    init();
  }
  Map<String, String> headers = {};
  Map<String, dynamic> context = {};
  int? signatureTimestamp;

  static const ytmDomain = 'music.youtube.com';
  static const httpsYtmDomain = 'https://music.youtube.com';
  static const baseApiEndpoint = '/youtubei/v1/';
  static const String ytmParams =
      '?alt=json&key=AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0';

  static final ValueNotifier<int> lastConnectionErrorTime =
      ValueNotifier<int>(0);
  ValueNotifier<int> get lastConnectionError => lastConnectionErrorTime;

  Future<void> init() async {
    refreshHeaders();
    refreshContext();
  }

  void refreshContext() {
    context = initializeContext();
  }

  void refreshHeaders() {
    headers = initializeHeaders();
    final visitorId = GetIt.I<SettingsManager>().visitorId;
    if (visitorId != null) {
      headers['X-Goog-Visitor-Id'] = visitorId;
    }
  }

  Future<void> resetVisitorId() async {
    Map<String, String> newHeaders = Map.from(headers);
    newHeaders.remove('X-Goog-Visitor-Id');
    final response = await sendGetRequest(httpsYtmDomain, newHeaders);
    final reg = RegExp(r'Secure-YEC=([^;]+)');
    final String? cookie = response.headers['set-cookie'];
    if (cookie == null) return;
    RegExpMatch? matches = reg.firstMatch(cookie);
    String? visitorId;
    if (matches == null) return;
    visitorId = matches.group(1).toString();
    GetIt.I<SettingsManager>().visitorId = visitorId;
    refreshHeaders();
  }

  void updateVisitorId(Map response) {
    final visitorId = response['responseContext']?['visitorData'];
    if (visitorId == null) return;
    final storedVisitorId = GetIt.I<SettingsManager>().visitorId;
    if (storedVisitorId == null || storedVisitorId != visitorId) {
      GetIt.I<SettingsManager>().visitorId = visitorId;
      refreshHeaders();
    }
  }

  static Future<String?> getVisitorid() async {
    Map<String, String> newHeaders = initializeHeaders();
    newHeaders.remove('X-Goog-Visitor-Id');
    final response = await _sendGetRequest(httpsYtmDomain, newHeaders);
    final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
    RegExpMatch? matches = reg.firstMatch(response.body);
    String? visitorId;
    if (matches != null) {
      final ytcfg = json.decode(matches.group(1).toString());
      visitorId = ytcfg['VISITOR_DATA']?.toString();
      return visitorId;
    }
    return null;
  }

  Future<Response> sendGetRequest(
    String url,
    Map<String, String>? headers,
  ) async {
    try {
      final Uri uri = Uri.parse(url);
      final Response response = await get(uri, headers: headers);
      return response;
    } catch (e) {
      debugPrint("Exception in YTClient::sendGetReques: $e");
      lastConnectionErrorTime.value = DateTime.now().millisecondsSinceEpoch;
      return Response.bytes([], 503);
    }
  }

  static Future<Response> _sendGetRequest(
    String url,
    Map<String, String>? headers,
  ) async {
    try {
      final Uri uri = Uri.parse(url);
      final Response response = await get(uri, headers: headers);
      return response;
    } catch (e) {
      debugPrint("Exception in YTClient::_sendGetRequest: $e");
      lastConnectionErrorTime.value = DateTime.now().millisecondsSinceEpoch;
      return Response.bytes([], 503);
    }
  }

  Future<Response> addPlayingStats(String videoId, Duration time) async {
    try {
      final Uri uri = Uri.parse(
          'https://music.youtube.com/api/stats/watchtime?ns=yt&ver=2&c=WEB_REMIX&cmt=${(time.inMilliseconds / 1000)}&docid=$videoId');
      final Response response = await get(uri, headers: headers);
      return response;
    } catch (e) {
      debugPrint("Exception in YTClient::addPlayingStats: $e");
      lastConnectionErrorTime.value = DateTime.now().millisecondsSinceEpoch;
      return Response.bytes([], 503);
    }
  }

  Future<Map> sendRequest(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers, String additionalParams = ''}) async {
    //
    try {
      body = {...body, ...context};

      this.headers.addAll(headers ?? {});

      if (this.headers['X-Goog-Visitor-Id'] == null &&
          GetIt.I<SettingsManager>().visitorId != null) {
        this.headers['X-Goog-Visitor-Id'] =
            GetIt.I<SettingsManager>().visitorId!;
      }
      final Uri uri = Uri.parse(httpsYtmDomain +
          baseApiEndpoint +
          endpoint +
          ytmParams +
          additionalParams);
      final response =
          await post(uri, headers: this.headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        final resp = json.decode(response.body) as Map;
        updateVisitorId(resp);
        return resp;
      } else {
        return {};
      }
    } catch (e) {
      debugPrint("Exception in YTClient::sendRequest: $e");
      lastConnectionErrorTime.value = DateTime.now().millisecondsSinceEpoch;
      return {};
    }
  }
}
