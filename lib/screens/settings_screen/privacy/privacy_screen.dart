import 'package:flutter/material.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/screens/settings_screen/setting_item.dart';
import 'package:gyawun/services/bottom_message.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:gyawun/utils/bottom_modals.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.select((SettingsManager s) => (
          playbackHistory: s.playbackHistory,
          searchHistory: s.searchHistory,
        ));
    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy"),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              GroupTitle(title: "Playback"),
              SettingSwitchTile(
                title: S.of(context).Enable_Playback_History,
                leading: Icon(Icons.manage_history_rounded),
                isFirst: true,
                value: settings.playbackHistory,
                onChanged: (value) async {
                  context.read<SettingsManager>().playbackHistory = value;
                },
              ),
              SettingTile(
                title: S.of(context).Delete_Playback_History,
                leading: Icon(Icons.playlist_remove_rounded),
                isLast: true,
                onTap: () async {
                  bool? confirm = await Modals.showConfirmBottomModal(
                    context,
                    message:
                        S.of(context).Delete_Playback_History_Confirm_Message,
                    isDanger: true,
                  );
                  if (confirm == true) {
                    await Hive.box('SONG_HISTORY').clear();
                    if (context.mounted) {
                      BottomMessage.showText(
                          context, S.of(context).Playback_History_Deleted);
                    }
                  }
                },
              ),
              GroupTitle(title: "Search"),
              SettingSwitchTile(
                title: S.of(context).Enable_Search_History,
                leading: Icon(Icons.saved_search_rounded),
                isFirst: true,
                value: settings.searchHistory,
                onChanged: (value) async {
                  context.read<SettingsManager>().searchHistory = value;
                },
              ),
              SettingTile(
                title: S.of(context).Delete_Search_History,
                leading: Icon(Icons.highlight_remove_sharp),
                isLast: true,
                onTap: () async {
                  bool? confirm = await Modals.showConfirmBottomModal(
                    context,
                    message:
                        S.of(context).Delete_Search_History_Confirm_Message,
                    isDanger: true,
                  );
                  if (confirm == true) {
                    await Hive.box('SEARCH_HISTORY').clear();
                    if (context.mounted) {
                      BottomMessage.showText(
                          context, S.of(context).Search_History_Deleted);
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
