import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/screens/settings_screen/setting_item.dart';
import 'package:gyawun/services/bottom_message.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:gyawun/utils/bottom_modals.dart';
import 'package:gyawun/ytmusic/ytmusic.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../themes/text_styles.dart';
import '../../../utils/adaptive_widgets/adaptive_widgets.dart';

class YtMusicScreen extends StatelessWidget {
  const YtMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.select((SettingsManager s) => (
          location: s.location,
          language: s.language,
          translateLyrics: s.translateLyrics,
          autofetchSongs: s.autofetchSongs,
          streamingQuality: s.streamingQuality,
          downloadQuality: s.downloadQuality,
          personalisedContent: s.personalisedContent,
          visitorId: s.visitorId,
        ));
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).YTMusic),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              GroupTitle(title: "General"),
              SettingTile(
                  title: S.of(context).Country,
                  leading: Icon(Icons.location_pin),
                  isFirst: true,
                  trailing: AdaptiveDropdownButton(
                    value: settings.location,
                    items: context
                        .read<SettingsManager>()
                        .locations
                        .map(
                          (location) => AdaptiveDropdownMenuItem(
                            value: location,
                            child: Text(
                              textAlign: TextAlign.right,
                              location['name']!.trim(),
                              style: smallTextStyle(context),
                              maxLines: 2,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (location) {
                      context.read<SettingsManager>().location = location!;
                    },
                  )),
              SettingTile(
                title: S.of(context).Language,
                leading: Icon(Icons.language),
                trailing: AdaptiveDropdownButton(
                  value: settings.language,
                  items: context
                      .read<SettingsManager>()
                      .languages
                      .map(
                        (language) => AdaptiveDropdownMenuItem(
                          value: language,
                          child: Text(
                            language['name']!.trim(),
                            style: smallTextStyle(context),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (language) {
                    context.read<SettingsManager>().language = language!;
                  },
                ),
              ),
              SettingSwitchTile(
                title: S.of(context).Translate_Lyrics,
                leading: Icon(Icons.translate_outlined),
                isLast: false,
                value: settings.translateLyrics,
                onChanged: (value) async {
                  context.read<SettingsManager>().translateLyrics = value;
                },
              ),
              SettingSwitchTile(
                title: S.of(context).Autofetch_Songs,
                leading: Icon(Icons.autorenew_outlined),
                isLast: true,
                value: settings.autofetchSongs,
                onChanged: (value) {
                  context.read<SettingsManager>().autofetchSongs = value;
                },
              ),
              GroupTitle(title: "Playback & download"),
              SettingTile(
                title: S.of(context).Streaming_Quality,
                leading: Icon(Icons.speaker_group_rounded),
                isFirst: true,
                // hasNavigation: false,
                trailing: AdaptiveDropdownButton(
                  value: settings.streamingQuality,
                  items: context
                      .read<SettingsManager>()
                      .audioQualities
                      .map(
                        (e) => AdaptiveDropdownMenuItem(
                          value: e,
                          child: Text(
                            textAlign: TextAlign.right,
                            e.name.toUpperCase(),
                            style: smallTextStyle(context),
                            maxLines: 2,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    context.read<SettingsManager>().streamingQuality = value;
                  },
                ),
              ),
              SettingTile(
                title: S.of(context).DOwnload_Quality,
                leading: Icon(Icons.cloud_download_rounded),
                isLast: true,
                trailing: AdaptiveDropdownButton(
                    value: settings.downloadQuality,
                    items: context
                        .read<SettingsManager>()
                        .audioQualities
                        .map(
                          (e) => AdaptiveDropdownMenuItem(
                            value: e,
                            child: Text(
                              e.name.toUpperCase(),
                              style: smallTextStyle(context, bold: false),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      context.read<SettingsManager>().downloadQuality = value;
                    }),
              ),
              GroupTitle(title: "Privacy"),
              SettingSwitchTile(
                title: S.of(context).Personalised_Content,
                leading: Icon(Icons.recommend_outlined),
                isFirst: true,
                value: settings.personalisedContent,
                onChanged: (value) async {
                  Modals.showCenterLoadingModal(context);
                  context.read<SettingsManager>().personalisedContent = value;
                  await GetIt.I<YTMusic>().resetVisitorId();

                  if (context.mounted) {
                    context.pop();
                  }
                },
              ),
              SettingTile(
                title: S.of(context).Enter_Visitor_Id,
                leading: Icon(Icons.edit),
                onTap: () async {
                  String? text = await Modals.showTextField(
                    context,
                    title: S.of(context).Enter_Visitor_Id,
                    hintText: S.of(context).Visitor_Id,
                  );
                  if (text != null) {
                    GetIt.I<SettingsManager>().visitorId = text;
                  }
                  GetIt.I<YTMusic>().refreshHeaders();
                },
              ),
              SettingTile(
                title: S.of(context).Reset_Visitor_Id,
                leading: Icon(CupertinoIcons.refresh_thick),
                isLast: true,
                onTap: () async {
                  Modals.showCenterLoadingModal(context);
                  await GetIt.I<YTMusic>().resetVisitorId();
                  if (context.mounted) {
                    context.pop();
                  }
                },
                trailing: settings.visitorId == null
                    ? null
                    : IconButton(
                        onPressed: () {
                          Clipboard.setData(
                                  ClipboardData(text: settings.visitorId ?? ''))
                              .then((val) {
                            GetIt.I<YTMusic>().refreshHeaders();
                            if (context.mounted) {
                              BottomMessage.showText(
                                  context, S.of(context).Copied_To_Clipboard);
                            }
                          });
                        },
                        icon: const Icon(Icons.copy),
                      ),
                subtitle: settings.visitorId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
