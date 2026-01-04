import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/screens/saved_screen/custom_playlist_header.dart';
import 'package:gyawun/services/favourites_manager.dart';

import '../../generated/l10n.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';
import 'library_tile.dart';

class FavouriteDetailsScreen extends StatelessWidget {
  const FavouriteDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: Text(S.of(context).Favourites),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: GetIt.I<FavouritesManager>().listenable,
        builder: (context, child) {
          final playlist = GetIt.I<FavouritesManager>().playlist;
          List songs = playlist["songs"];
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: CustomPlayistHeader(
                      playlist: playlist,
                      bottomModal: Modals.showFavouritesBottomModal,
                      icon: AdaptiveIcons.heart_fill,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = songs[index];
                        final videoId = song['videoId'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: SwipeActionCell(
                            key: ValueKey(videoId),
                            backgroundColor: Colors.transparent,
                            trailingActions: <SwipeAction>[
                              SwipeAction(
                                  title: S.of(context).Remove,
                                  onTap: (CompletionHandler handler) async {
                                    Modals.showConfirmBottomModal(context,
                                            message:
                                                S.of(context).Remove_Message,
                                            isDanger: true)
                                        .then(
                                      (bool confirm) async {
                                        if (confirm) {
                                          await GetIt.I<FavouritesManager>()
                                              .remove(song);
                                        } else {
                                          handler(false);
                                        }
                                      },
                                    );
                                  },
                                  color: Colors.red),
                            ],
                            child: LibraryTile(song: song),
                          ),
                        );
                      },
                      childCount: songs.length,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
