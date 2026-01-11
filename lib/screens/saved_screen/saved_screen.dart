import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/services/favourites_manager.dart';
import 'package:gyawun/services/history_manager.dart';
import 'package:gyawun/utils/extensions.dart';
import 'package:gyawun/utils/internet_guard.dart';
import 'package:gyawun/utils/playlist_thumbnail.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../services/library.dart';
import '../../themes/colors.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Map playlists = context.watch<LibraryService>().playlists;
    return InternetGuard(
      child: AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          title: Text(S.of(context).Saved),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            AdaptiveIconButton(
              onPressed: () {
                Modals.showImportplaylistModal(context);
              },
              icon: Icon(
                AdaptiveIcons.import,
                size: 25,
              ),
            ),
            AdaptiveIconButton(
              onPressed: () {
                Modals.showCreateplaylistModal(context);
              },
              icon: Icon(
                AdaptiveIcons.add,
                size: 25,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  AdaptiveListTile(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    title: Text(S.of(context).Favourites),
                    leading: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: greyColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        AdaptiveIcons.heart_fill,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: ListenableBuilder(
                      listenable: GetIt.I<FavouritesManager>().listenable,
                      builder: (context, child) {
                        return Text(S
                            .of(context)
                            .nSongs(GetIt.I<FavouritesManager>().songsCount));
                      },
                    ),
                    trailing: Icon(AdaptiveIcons.chevron_right),
                    onTap: () => context.push('/saved/favourite_details'),
                    onSecondaryTap: () {
                      Modals.showFavouritesBottomModal(
                        context,
                        GetIt.I<FavouritesManager>().playlist,
                      );
                    },
                    onLongPress: () {
                      Modals.showFavouritesBottomModal(
                        context,
                        GetIt.I<FavouritesManager>().playlist,
                      );
                    },
                  ),
                  AdaptiveListTile(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    title: Text(S.of(context).Downloads),
                    leading: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: greyColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        AdaptiveIcons.download,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: ValueListenableBuilder(
                      valueListenable:
                          GetIt.I<DownloadManager>().downloadsNotifier,
                      builder: (context, downloads, child) {
                        return Text(S.of(context).nSongs(downloads.length));
                      },
                    ),
                    trailing: Icon(AdaptiveIcons.chevron_right),
                    onTap: () => context.push('/saved/downloads'),
                    onSecondaryTap: () {
                      Modals.showDownloadBottomModal(context);
                    },
                    onLongPress: () {
                      Modals.showDownloadBottomModal(context);
                    },
                  ),
                  AdaptiveListTile(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    title: Text(S.of(context).History),
                    leading: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: greyColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.history,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: ListenableBuilder(
                      listenable: GetIt.I<HistoryManager>().songs.listenable,
                      builder: (context, child) {
                        return Text(S
                            .of(context)
                            .nSongs(GetIt.I<HistoryManager>().songs.count));
                      },
                    ),
                    trailing: Icon(AdaptiveIcons.chevron_right),
                    onTap: () => context.push('/saved/history'),
                  ),
                  Column(
                    children: SplayTreeMap.from(playlists)
                        .map((key, item) {
                          return MapEntry(
                            key,
                            item == null
                                ? const SizedBox.shrink()
                                : AdaptiveListTile(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    onSecondaryTap: () {
                                      if (item['videoId'] == null &&
                                          item['playlistId'] != null) {
                                        Modals.showPlaylistBottomModal(
                                            context, item);
                                      } else if (item['isPredefined'] ==
                                          false) {
                                        Modals.showPlaylistBottomModal(context,
                                            {...item, 'playlistId': key});
                                      }
                                    },
                                    onLongPress: () {
                                      if (item['videoId'] == null &&
                                          item['playlistId'] != null) {
                                        Modals.showPlaylistBottomModal(
                                            context, item);
                                      } else if (item['isPredefined'] ==
                                          false) {
                                        Modals.showPlaylistBottomModal(context,
                                            {...item, 'playlistId': key});
                                      }
                                    },
                                    onTap: () {
                                      if (item['isPredefined']) {
                                        context.push(
                                          '/browse',
                                          extra: {
                                            'endpoint': item['endpoint']
                                                .cast<String, dynamic>()
                                          },
                                        );
                                      } else {
                                        context.push(
                                          '/saved/playlist_details',
                                          extra: {'playlistkey': key},
                                        );
                                      }
                                    },
                                    title: Text(
                                      item['title'],
                                      maxLines: 2,
                                    ),
                                    leading: item['isPredefined'] == true
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                item['type'] == 'ARTIST'
                                                    ? 50
                                                    : 3),
                                            child: CachedNetworkImage(
                                              imageUrl: item['thumbnails']
                                                  .first['url']
                                                  .replaceAll(
                                                      'w540-h225', 'w60-h60'),
                                              height: 50,
                                              width: 50,
                                            ))
                                        : (item['songs'] != null &&
                                                item['songs']?.length > 0)
                                            ? PlaylistThumbnail(
                                                playslist:
                                                    item['isPredefined'] == true
                                                        ? item
                                                        : item['songs'],
                                                size: 50,
                                                radius: item['type'] == 'ARTIST'
                                                    ? 50
                                                    : 8,
                                              )
                                            : Container(
                                                height: 50,
                                                width: 50,
                                                decoration: BoxDecoration(
                                                  color: greyColor,
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                                child: Icon(
                                                  CupertinoIcons
                                                      .music_note_list,
                                                  color: context.isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                    subtitle: (item['songs'] != null ||
                                            item['isPredefined'])
                                        ? Text(
                                            item['isPredefined'] == true
                                                ? item['subtitle']
                                                : S.of(context).nSongs(
                                                    item['songs'].length),
                                            maxLines: 1,
                                          )
                                        : null,
                                    trailing: Icon(AdaptiveIcons.chevron_right),
                                  ),
                          );
                        })
                        .values
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
