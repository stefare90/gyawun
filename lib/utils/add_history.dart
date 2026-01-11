import 'package:get_it/get_it.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:gyawun/services/history_manager.dart';

import '../ytmusic/ytmusic.dart';

Future<void> addHistory(Map song) async {
  await GetIt.I<HistoryManager>().songs.add(song);
  final downloadSong = GetIt.I<DownloadManager>().downloads[song['videoId']];
  if (GetIt.I<SettingsManager>().personalisedContent &&
      (downloadSong == null || downloadSong['status'] != 'DOWNLOADED')) {
    GetIt.I<YTMusic>().addYoutubeHistory(song['videoId']);
  }
}
