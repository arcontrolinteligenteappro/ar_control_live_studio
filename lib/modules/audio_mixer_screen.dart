import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/services/service_locator.dart';
import 'package:ar_control_live_studio/modules/audio_module.dart';

class AudioMixerScreen extends StatefulWidget {
  const AudioMixerScreen({super.key});

  @override
  State<AudioMixerScreen> createState() => _AudioMixerScreenState();
}

class _AudioMixerScreenState extends State<AudioMixerScreen> {
  final AudioEngine _audioEngine = ServiceLocator.audioEngine;
  late Stream<Map<String, dynamic>> _audioStream;
  Map<String, dynamic> _currentStatus = {};

  @override
  void initState() {
    super.initState();
    _audioStream = _audioEngine.audioStatus;
    _audioEngine.initialize();

    _audioStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final channels = _currentStatus['channels'] as Map<String, dynamic>? ?? {};
    final masterVolume = _currentStatus['masterVolume'] as double? ?? 1.0;
    final masterMute = _currentStatus['masterMute'] as bool? ?? false;
    final levels = _currentStatus['levels'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('AUDIO MIXER PRO', style: TextStyle(color: Colors.cyanAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _currentStatus['recording'] == true ? Icons.stop : Icons.mic,
              color: _currentStatus['recording'] == true ? Colors.redAccent : Colors.greenAccent,
            ),
            onPressed: () {
              if (_currentStatus['recording'] == true) {
                _audioEngine.stopRecording();
              } else {
                _audioEngine.startRecording('session_${DateTime.now().millisecondsSinceEpoch}.wav');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Channel Strips
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channelId = channels.keys.elementAt(index);
                  final channel = channels[channelId] as Map<String, dynamic>;
                  final level = levels[channelId] as double? ?? 0.0;

                  return _buildChannelStrip(channelId, channel, level);
                },
              ),
            ),

            const SizedBox(height: 20),

            // Master Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'MASTER OUTPUT',
                    style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Master Fader
                      SizedBox(
                        width: 60,
                        child: Column(
                          children: [
                            RotatedBox(
                              quarterTurns: 3,
                              child: Slider(
                                value: masterVolume,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (value) {
                                  _audioEngine.setMasterVolume(value);
                                },
                                activeColor: Colors.cyanAccent,
                                inactiveColor: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${(masterVolume * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Master Level Meter
                      _buildLevelMeter(levels['master'] as double? ?? 0.0, height: 100),

                      const SizedBox(width: 20),

                      // Master Controls
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              masterMute ? Icons.volume_off : Icons.volume_up,
                              color: masterMute ? Colors.redAccent : Colors.greenAccent,
                            ),
                            onPressed: () => _audioEngine.toggleMasterMute(),
                          ),
                          const Text('MUTE', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // EQ Section
            _buildEQSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelStrip(String channelId, Map<String, dynamic> channel, double level) {
    final volume = channel['volume'] as double? ?? 0.0;
    final pan = channel['pan'] as double? ?? 0.0;
    final mute = channel['mute'] as bool? ?? false;
    final name = channel['name'] as String? ?? channelId;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Channel Name
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // Level Meter
          _buildLevelMeter(level),

          const SizedBox(height: 10),

          // Volume Fader
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: volume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) => _audioEngine.setChannelVolume(channelId, value),
                activeColor: Colors.cyanAccent,
                inactiveColor: Colors.grey.shade600,
              ),
            ),
          ),

          // Volume Value
          Text(
            '${(volume * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),

          const SizedBox(height: 10),

          // Pan Control
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('L', style: TextStyle(color: Colors.white, fontSize: 10)),
              SizedBox(
                width: 60,
                child: Slider(
                  value: pan,
                  min: -1.0,
                  max: 1.0,
                  onChanged: (value) => _audioEngine.setChannelPan(channelId, value),
                  activeColor: Colors.orangeAccent,
                  inactiveColor: Colors.grey.shade600,
                ),
              ),
              const Text('R', style: TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),

          // Mute Button
          IconButton(
            icon: Icon(
              mute ? Icons.mic_off : Icons.mic,
              color: mute ? Colors.redAccent : Colors.greenAccent,
              size: 20,
            ),
            onPressed: () => _audioEngine.toggleChannelMute(channelId),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelMeter(double level, {double height = 60}) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 6,
          height: height * level,
          decoration: BoxDecoration(
            color: level > 0.8 ? Colors.redAccent : Colors.greenAccent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildEQSection() {
    final eqBands = _currentStatus['eqBands'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'MASTER EQUALIZER',
            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: eqBands.entries.map((entry) {
              final band = entry.key;
              final bandData = entry.value as Map<String, dynamic>;
              final gain = bandData['gain'] as double? ?? 0.0;
              final frequency = bandData['frequency'] as double? ?? 1000.0;

              return Column(
                children: [
                  Text(
                    '${frequency.toInt()}Hz',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 80,
                    width: 40,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: gain,
                        min: -12.0,
                        max: 12.0,
                        onChanged: (value) => _audioEngine.setEQBand(band, value),
                        activeColor: Colors.purpleAccent,
                        inactiveColor: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Text(
                    '${gain.toStringAsFixed(1)}dB',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}