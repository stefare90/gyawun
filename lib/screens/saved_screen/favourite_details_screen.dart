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
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListenableBuilder(
                listenable: GetIt.I<FavouritesManager>().listenable,
                builder: (context, child) {
                  Map<String, dynamic> songs =
                      Map.from(GetIt.I<FavouritesManager>().songs);
                  return Column(
                    children: [
                      CustomPlayistHeader(
                        playlist: GetIt.I<FavouritesManager>().playlist,
                        bottomModal: Modals.showFavouritesBottomModal,
                        icon: AdaptiveIcons.heart_fill,
                      ),
                      Column(
                        children: songs
                            .map((key, song) {
                              return MapEntry(
                                  key,
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: SwipeActionCell(
                                      key: ObjectKey(key),
                                      backgroundColor: Colors.transparent,
                                      trailingActions: <SwipeAction>[
                                        SwipeAction(
                                            title: S.of(context).Remove,
                                            onTap: (CompletionHandler
                                                handler) async {
                                              Modals.showConfirmBottomModal(
                                                      context,
                                                      message: S
                                                          .of(context)
                                                          .Remove_Message,
                                                      isDanger: true)
                                                  .then(
                                                (bool confirm) async {
                                                  if (confirm) {
                                                    await GetIt.I<
                                                            FavouritesManager>()
                                                        .remove(song);
                                                  }
                                                },
                                              );
                                            },
                                            color: Colors.red),
                                      ],
                                      child: LibraryTile(song: song),
                                    ),
                                  ));
                            })
                            .values
                            .toList(),
                      ),
                    ],
                  );
                }),
          ),
        ),
      ),
    );
  }
}
