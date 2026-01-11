import 'dart:io';

import 'package:easy_folder_picker/FolderPicker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/screens/settings_screen/setting_item.dart';
import 'package:gyawun/services/bottom_message.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/services/favourites_manager.dart';
import 'package:gyawun/services/file_storage.dart';
import 'package:gyawun/services/library.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:gyawun/themes/text_styles.dart';
import 'package:gyawun/utils/bottom_modals.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../utils/adaptive_widgets/adaptive_widgets.dart';

class BackupStorageScreen extends StatelessWidget {
  const BackupStorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings =
        context.select((SettingsManager s) => ((appFolder: s.appFolder)));
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Backup_And_Restore),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (Platform.isAndroid) ...[
                GroupTitle(title: "Storage"),
                SettingTile(
                    title: "App Folder",
                    leading: Icon(CupertinoIcons.folder),
                    isFirst: true,
                    isLast: true,
                    subtitle: settings.appFolder,
                    trailing: AdaptiveOutlinedButton(
                        child: const Text('Change'),
                        onPressed: () async {
                          final appFolder =
                              Directory(GetIt.I<SettingsManager>().appFolder);
                          final rootDirectory = await appFolder.exists()
                              ? appFolder
                              : Directory(FileStorage.defaultPath);
                          if (!context.mounted) return;
                          Directory? newDirectory = await FolderPicker.pick(
                              allowFolderCreation: true,
                              context: context,
                              rootDirectory: rootDirectory,
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))));
                          if (newDirectory != null) {
                            GetIt.I<SettingsManager>().appFolder =
                                newDirectory.path;
                            await GetIt.I<FileStorage>().setupPaths();
                          }
                        })),
              ],
              GroupTitle(title: S.of(context).Backup_And_Restore),
              SettingTile(
                title: S.of(context).Backup,
                leading: Icon(Icons.backup_outlined),
                isFirst: true,
                onTap: () => _backup(context),
              ),
              SettingTile(
                title: S.of(context).Restore,
                leading: Icon(Icons.restore_outlined),
                isLast: true,
                onTap: () async {
                  bool success =
                      await GetIt.I<FileStorage>().loadBackup(context);
                  if (context.mounted) {
                    if (success) {
                      BottomMessage.showText(
                          context, S.of(context).Restore_Success);
                    } else {
                      BottomMessage.showText(
                          context, S.of(context).Restore_Failed);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _backup(BuildContext context) async {
  String? action;
  List? items;
  (String?, List?)? response = await showModalBottomSheet(
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        ValueNotifier<List<Map<String, dynamic>>> items = ValueNotifier([
          {'name': 'Favourites', 'selected': false},
          {'name': 'Playlists', 'selected': false},
          {'name': 'Settings', 'selected': false},
          {'name': 'Song History', 'selected': false},
          {'name': 'Downloads', 'selected': false}
        ]);
        return BottomModalLayout(
          title: Text(S.of(context).Select_Backup,
              style: mediumTextStyle(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder(
                valueListenable: items,
                builder: (context, backups, child) {
                  return Column(
                      children: backups.indexed.map((el) {
                    int index = el.$1;
                    Map<String, dynamic> element = el.$2;
                    return CheckboxListTile(
                      title: Text(element['name']),
                      value: element['selected'],
                      onChanged: (val) {
                        List<Map<String, dynamic>> newItems =
                            List.from(items.value);
                        newItems[index]['selected'] = val;
                        items.value = newItems;
                      },
                    );
                  }).toList());
                },
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 20,
                  children: [
                    MaterialButton(
                      onPressed: () {
                        List finalItems = items.value
                            .where((el) => el['selected'] == true)
                            .map((el) => el['name'].toLowerCase())
                            .toList();
                        context.pop(finalItems.isEmpty
                            ? (null, null)
                            : ("Share", finalItems));
                      },
                      color: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        S.of(context).Share,
                        style: TextStyle(
                            color: Theme.of(context).scaffoldBackgroundColor),
                      ),
                    ),
                    MaterialButton(
                      onPressed: () {
                        List finalItems = items.value
                            .where((el) => el['selected'] == true)
                            .map((el) => el['name'].toLowerCase())
                            .toList();
                        context.pop(finalItems.isEmpty
                            ? (null, null)
                            : ("Save", finalItems));
                      },
                      color: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        S.of(context).Save,
                        style: TextStyle(
                            color: Theme.of(context).scaffoldBackgroundColor),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      });
  if (response == null) return;
  (action, items) = response;
  if (action == null || items == null) {
    return;
  }
  Map backup = {
    'name': 'Gyawun',
    'type': 'backup',
    'version': 1,
    'data': {},
  };
  if (items.contains('playlists')) {
    Map playlists = GetIt.I<LibraryService>().playlists;
    backup['data']['playlists'] = playlists;
  }
  if (items.contains('settings')) {
    Map settings = GetIt.I<SettingsManager>().settings;
    settings.remove('YTMUSIC_AUTH');
    backup['data']['settings'] = settings;
  }
  if (items.contains('favourites')) {
    Map favourites = GetIt.I<FavouritesManager>().songs;
    backup['data']['favourites'] = favourites;
  }
  if (items.contains('song history')) {
    Map history = Hive.box('SONG_HISTORY').toMap();
    backup['data']['song_history'] = history;
  }
  if (items.contains('downloads')) {
    Map downloads = GetIt.I<DownloadManager>().downloads;
    backup['data']['downloads'] = downloads;
  }
  String? backupPath = "";
  if (action == 'Save') {
    backupPath = await GetIt.I<FileStorage>().saveBackUp(backup);
  } else if (action == 'Share') {
    backupPath = await GetIt.I<FileStorage>().shareBackUp(backup);
  }
  if (context.mounted) {
    if (backupPath == "") {
      BottomMessage.showText(context, S.of(context).Backup_Failed);
    } else {
      BottomMessage.showText(
          context, '${S.of(context).Backup_Success} $backupPath');
    }
  }
}
