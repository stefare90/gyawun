import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/screens/settings_screen/setting_item.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../services/media_player.dart';
import '../../../services/settings_manager.dart';
import '../../../themes/text_styles.dart';
import '../../../utils/adaptive_widgets/adaptive_widgets.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.select((SettingsManager s) => (
          loudnessEnabled: s.loudnessEnabled,
          equalizerEnabled: s.equalizerEnabled,
        ));
    return ClipRRect(
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(S().Loudness_And_Equalizer,
              style: mediumTextStyle(context, bold: false)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              children: [
                GroupTitle(title: "Loudness"),
                SettingSwitchTile(
                  leading: Icon(Icons.volume_up),
                  title: S.of(context).Loudness_Enhancer,
                  isFirst: true,
                  value: settings.loudnessEnabled,
                  onChanged: (value) async {
                    await GetIt.I<MediaPlayer>().setLoudnessEnabled(value);
                  },
                ),
                SettingEmptyTile(
                  leading: Icon(Icons.tune),
                  isLast: true,
                  child: LoudnessControls(
                      disabled: settings.loudnessEnabled == false),
                ),
                GroupTitle(title: "Equalizer"),
                SettingSwitchTile(
                  title: S.of(context).Enable_Equalizer,
                  leading: Icon(Icons.equalizer),
                  isFirst: true,
                  value: settings.equalizerEnabled,
                  onChanged: (value) async {
                    await GetIt.I<MediaPlayer>().setEqualizerEnabled(value);
                  },
                ),
                SettingEmptyTile(
                  isLast: true,
                  child: EqualizerControls(
                    disabled: !settings.equalizerEnabled,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EqualizerControls extends StatelessWidget {
  const EqualizerControls({
    this.disabled = false,
    super.key,
  });
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GetIt.I<MediaPlayer>().getEqualizerParameters(),
      builder: (context, snapshot) {
        final parameters = snapshot.data;
        if (parameters == null) {
          return SizedBox(
            child: Text(
              S.of(context).View_Equalizer,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 300,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              for (var band in parameters['bands'])
                Expanded(
                  child: VerticalSlider(
                    min: parameters['minDecibels'],
                    max: parameters['maxDecibels'],
                    value: band['gain'],
                    bandIndex: band['index'] as int,
                    disabled: disabled,
                    centerFrequency: band['centerFrequency'].round(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class LoudnessControls extends StatelessWidget {
  const LoudnessControls({this.disabled = false, super.key});
  final bool disabled;
  @override
  Widget build(BuildContext context) {
    final loudnessTargetGain =
        context.select<SettingsManager, double>((s) => s.loudnessTargetGain);
    return Slider(
      min: -1,
      max: 1,
      value: loudnessTargetGain,
      onChanged: disabled
          ? null
          : (val) async {
              await GetIt.I<MediaPlayer>().setLoudnessTargetGain(val);
            },
      label: loudnessTargetGain.toString(),
    );
  }
}

class VerticalSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int bandIndex;
  final bool disabled;
  final int centerFrequency;

  const VerticalSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.bandIndex,
    required this.centerFrequency,
    this.disabled = false,
  });

  @override
  State<VerticalSlider> createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  double? sliderValue;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text((sliderValue ?? widget.value).toStringAsFixed(2)),
        Expanded(
          child: AdaptiveSlider(
            value: sliderValue ?? widget.value,
            min: widget.min,
            max: widget.max,
            disabled: widget.disabled,
            vertical: true,
            onChanged: (val) {
              setState(() {
                sliderValue = val;
                GetIt.I<MediaPlayer>()
                    .setEqualizerBandGain(widget.bandIndex, val);
              });
            },
          ),
        ),
        Text('${widget.centerFrequency} Hz'),
      ],
    );
  }
}
