import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:gyawun/screens/saved_screen/custom_playlist_header.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../services/bottom_message.dart';
import '../../services/library.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';
import '../home_screen/section_item.dart';

class PlaylistDetailsScreen extends StatelessWidget {
  const PlaylistDetailsScreen({required this.playlistkey, super.key});
  final String playlistkey;

  @override
  Widget build(BuildContext context) {
    Map? playlist = context.watch<LibraryService>().getPlaylist(playlistkey);
    return playlist == null
        ? AdaptiveScaffold(
            appBar: AdaptiveAppBar(),
            body: Center(
              child: Text(
                S.of(context).Playlist_Not_Available,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          )
        : AdaptiveScaffold(
            appBar: AdaptiveAppBar(
              title: Text(playlist['title']),
              centerTitle: true,
            ),
            body: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(
                  children: [
                    CustomPlayistHeader(
                      playlist: {...playlist, 'playlistId': playlistkey},
                      bottomModal: Modals.showPlaylistBottomModal,
                    ),
                    const SizedBox(height: 8),
                    ListView(
                      shrinkWrap: true,
                      primary: false,
                      children: [
                        ...playlist['songs'].map<Widget>((song) {
                          return SwipeActionCell(
                            backgroundColor: Colors.transparent,
                            key: ObjectKey(song['videoId']),
                            trailingActions: <SwipeAction>[
                              SwipeAction(
                                  title: S.of(context).Remove,
                                  onTap: (CompletionHandler handler) async {
                                    Modals.showConfirmBottomModal(
                                      context,
                                      message: S.of(context).Remove_Message,
                                      isDanger: true,
                                    ).then((bool confirm) {
                                      if (confirm) {
                                        context
                                            .read<LibraryService>()
                                            .removeFromPlaylist(
                                                item: song,
                                                playlistId: playlistkey)
                                            .then((message) =>
                                                BottomMessage.showText(
                                                    context, message));
                                      } else {
                                        handler(false);
                                      }
                                    });
                                  },
                                  color: Colors.red),
                            ],
                            child:
                                SongTile(song: song, playlistId: playlistkey),
                          );
                        }).toList()
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
  }
}
