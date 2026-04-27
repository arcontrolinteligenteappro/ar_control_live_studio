import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Corrected import
import 'package:ar_control_live_studio/providers/app_state.dart';

class SportsModule extends ConsumerStatefulWidget {
  const SportsModule({super.key});

  @override
  ConsumerState<SportsModule> createState() => _SportsModuleState();
}

class _SportsModuleState extends ConsumerState<SportsModule> {
  String _selectedSport = 'Baseball';
  int _homeScore = 0;
  int _awayScore = 0;
  int _inning = 1;
  int _balls = 0;
  int _strikes = 0;
  int _outs = 0;
  Timer? _timer;
  Duration _gameTime = Duration.zero;
  bool _isTimerRunning = false;
  final Duration _basketballQuarterDuration = const Duration(minutes: 12);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer({bool countdown = false}) {
    if (_isTimerRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (countdown) {
          if (_gameTime.inSeconds > 0) {
            _gameTime -= const Duration(seconds: 1);
          } else {
            _stopTimer();
          }
        } else {
          _gameTime += const Duration(seconds: 1);
        }
        _updateOverlayData();
      });
    });
    setState(() {
      _isTimerRunning = true;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      if (_selectedSport == 'Basketball') {
        _gameTime = _basketballQuarterDuration;
      } else {
        _gameTime = Duration.zero;
      }
      _updateOverlayData();
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _addStrike() {
    _strikes++;
    if (_strikes >= 3) {
      _addOut();
    }
  }

  void _addBall() {
    _balls++;
    if (_balls >= 4) {
      _balls = 0;
      _strikes = 0;
    }
  }

  void _addOut() {
    _outs++;
    _balls = 0;
    _strikes = 0;
    if (_outs >= 3) {
      _outs = 0;
      _inning++;
    }
  }

  void _updateOverlayData() {
    // Si requieres enviar datos a la superposición visual (Overlay Engine)
    // se maneja desde aquí, pero retiramos la variable 'overlay' local que no se usaba
    Map<String, dynamic> data = {
      'scoreHome': _homeScore,
      'scoreAway': _awayScore,
      'home': 'HOME',
      'away': 'AWAY',
    };

    switch (_selectedSport) {
      case 'Baseball':
        data['period'] = 'INN $_inning';
        data['details'] = 'B: $_balls S: $_strikes O: $_outs';
        break;
      case 'Soccer':
        data['period'] = _gameTime.inMinutes < 45 ? '1ST HALF' : '2ND HALF';
        data['time'] = _formatDuration(_gameTime);
        break;
      case 'Basketball':
        data['period'] = 'Q4'; 
        data['time'] = _formatDuration(_gameTime);
        break;
    }
    
    // Aquí puedes llamar al método de tu engine si lo tienes habilitado.
    // Provider.of<OverlayEngine>(context, listen: false).updateOverlayData('scoreboard_main', data);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final textColor = appState.isDarkTheme ? Colors.white : const Color(0xFF000080);

    return Container(
      color: appState.isDarkTheme ? const Color(0xFF000080) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButton<String>(
            value: _selectedSport,
            items: [
              DropdownMenuItem(value: 'Baseball', child: Text('⚾ Baseball', style: TextStyle(color: textColor))),
              DropdownMenuItem(value: 'Soccer', child: Text('⚽ Soccer', style: TextStyle(color: textColor))),
              DropdownMenuItem(value: 'Basketball', child: Text('🏀 Basketball', style: TextStyle(color: textColor))),
            ],
            onChanged: (value) {
              _stopTimer();
              setState(() {
                _selectedSport = value ?? 'Baseball';
                _homeScore = 0;
                _awayScore = 0;
                _inning = 1;
                _balls = 0;
                _strikes = 0;
                _outs = 0;
                _resetTimer();
                _updateOverlayData();
              });
            },
            dropdownColor: appState.isDarkTheme ? const Color(0xFF000080) : Colors.white,
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 20),
          if (_selectedSport == 'Baseball') _buildBaseballScoreboard(appState)
          else if (_selectedSport == 'Soccer') _buildSoccerScoreboard(appState)
          else _buildBasketballScoreboard(appState),
        ],
      ),
    );
  }

  Widget _buildBaseballScoreboard(AppState appState) {
    return Column(
      children: [
        Text('BASEBALL SCOREBOARD', style: TextStyle(color: appState.isDarkTheme ? Colors.cyanAccent : const Color(0xFF000080), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Courier New')),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildScoreCard('HOME', _homeScore, appState),
            _buildScoreCard('AWAY', _awayScore, appState),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text('INNING $_inning', style: TextStyle(color: appState.isDarkTheme ? Colors.white : const Color(0xFF000080), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _inning++;
                      _updateOverlayData();
                    });
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
            Column(
              children: [
                Text('B: $_balls S: $_strikes O: $_outs', style: TextStyle(color: appState.isDarkTheme ? Colors.white : const Color(0xFF000080), fontFamily: 'Courier New')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(onPressed: () { setState(() { _addBall(); _updateOverlayData(); }); }, child: const Text('Ball')),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: () { setState(() { _addStrike(); _updateOverlayData(); }); }, child: const Text('Strike')),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: () { setState(() { _addOut(); _updateOverlayData(); }); }, child: const Text('Out')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSoccerScoreboard(AppState appState) {
    return Column(
      children: [
        Text('SOCCER MATCH', style: TextStyle(color: appState.isDarkTheme ? Colors.cyanAccent : const Color(0xFF000080), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Courier New')),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildScoreCard('HOME', _homeScore, appState),
            _buildScoreCard('AWAY', _awayScore, appState),
          ],
        ),
        const SizedBox(height: 20),
        _buildTimerControls(appState, isCountdown: false),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () { setState(() { _homeScore++; _updateOverlayData(); }); }, child: const Text('Home Goal +')),
            ElevatedButton(onPressed: () { setState(() { _awayScore++; _updateOverlayData(); }); }, child: const Text('Away Goal +')),
          ],
        ),
      ],
    );
  }

  Widget _buildBasketballScoreboard(AppState appState) {
    return Column(
      children: [
        Text('BASKETBALL GAME', style: TextStyle(color: appState.isDarkTheme ? Colors.cyanAccent : const Color(0xFF000080), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Courier New')),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildScoreCard('HOME', _homeScore, appState),
            _buildScoreCard('AWAY', _awayScore, appState),
          ],
        ),
        const SizedBox(height: 20),
        _buildTimerControls(appState, isCountdown: true),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () { setState(() { _homeScore += 3; _updateOverlayData(); }); }, child: const Text('Home +3')),
            ElevatedButton(onPressed: () { setState(() { _homeScore += 2; _updateOverlayData(); }); }, child: const Text('Home +2')),
            ElevatedButton(onPressed: () { setState(() { _awayScore += 3; _updateOverlayData(); }); }, child: const Text('Away +3')),
            ElevatedButton(onPressed: () { setState(() { _awayScore += 2; _updateOverlayData(); }); }, child: const Text('Away +2')),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerControls(AppState appState, {bool isCountdown = false}) {
    return Column(
      children: [
        Text(
          _formatDuration(_gameTime),
          style: TextStyle(fontFamily: 'Courier New', fontSize: 36, fontWeight: FontWeight.bold, color: appState.isDarkTheme ? Colors.cyanAccent : const Color(0xFF000080)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _isTimerRunning ? _stopTimer : () => _startTimer(countdown: isCountdown), child: Text(_isTimerRunning ? 'Stop' : 'Start')),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: _resetTimer, child: const Text('Reset')),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreCard(String team, int score, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: appState.isDarkTheme ? Colors.cyanAccent : const Color(0xFF000080), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(team, style: TextStyle(color: appState.isDarkTheme ? Colors.white : const Color(0xFF000080), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(score.toString(), style: TextStyle(color: appState.isDarkTheme ? Colors.cyanAccent : const Color(0xFF000080), fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'Courier New')),
        ],
      ),
    );
  }
}