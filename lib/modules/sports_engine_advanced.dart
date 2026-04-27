import 'package:flutter/foundation.dart';

class AthleteStats {
  final String id;
  final String name;
  final int number;
  int points = 0;
  int rebounds = 0;
  int assists = 0;
  int fouls = 0;
  int steals = 0;
  int blocks = 0;
  double fieldGoalPercentage = 0.0;
  String status = 'ACTIVE'; // ACTIVE, BENCH, INJURED

  AthleteStats({
    required this.id,
    required this.name,
    required this.number,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'number': number,
    'points': points,
    'rebounds': rebounds,
    'assists': assists,
    'fouls': fouls,
    'steals': steals,
    'blocks': blocks,
    'fieldGoalPercentage': fieldGoalPercentage,
    'status': status,
  };
}

class TeamStats {
  final String id;
  final String name;
  final String logo;
  int score = 0;
  int timeouts = 0;
  int fouls = 0;
  int period = 1;
  Duration timeRemaining = const Duration(minutes: 12);
  final List<AthleteStats> athletes = [];

  TeamStats({
    required this.id,
    required this.name,
    required this.logo,
  });

  int get totalPoints => athletes.fold(0, (sum, a) => sum + a.points);
  int get totalRebounds => athletes.fold(0, (sum, a) => sum + a.rebounds);
  int get totalAssists => athletes.fold(0, (sum, a) => sum + a.assists);

  void addAthlete(AthleteStats athlete) => athletes.add(athlete);
  void removeAthlete(String athleteId) => athletes.removeWhere((a) => a.id == athleteId);
}

class SportsEngineAdvanced extends ChangeNotifier {
  late TeamStats _homeTeam;
  late TeamStats _awayTeam;
  
  final String _currentSport = 'Basketball'; // Basketball, Soccer, Baseball, Hockey
  String _gameStatus = 'LIVE'; // LIVE, PAUSE, END, PRE_GAME
  
  final List<Map<String, dynamic>> _playLog = [];
  final List<String> _replayQueue = [];
  
  int _currentPeriod = 1;
  Duration _gameTime = Duration.zero;
  
  String _lastEventDescription = '';
  
  // Graphics overlay
  bool _showScoreboard = true;
  bool _showLowerThird = false;
  bool _showStatsOverlay = false;
  String _lowerThirdText = '';
  
  // Getters
  TeamStats get homeTeam => _homeTeam;
  TeamStats get awayTeam => _awayTeam;
  String get currentSport => _currentSport;
  String get gameStatus => _gameStatus;
  int get currentPeriod => _currentPeriod;
  Duration get gameTime => _gameTime;
  List<Map<String, dynamic>> get playLog => _playLog;
  String get lastEventDescription => _lastEventDescription;
  bool get showScoreboard => _showScoreboard;
  bool get showLowerThird => _showLowerThird;
  bool get showStatsOverlay => _showStatsOverlay;
  String get lowerThirdText => _lowerThirdText;

  SportsEngineAdvanced() {
    _initializeTeams();
  }

  void _initializeTeams() {
    _homeTeam = TeamStats(
      id: 'home',
      name: 'HOME TEAM',
      logo: 'assets/logos/home.png',
    );

    _awayTeam = TeamStats(
      id: 'away',
      name: 'AWAY TEAM',
      logo: 'assets/logos/away.png',
    );

    // Add default athletes
    for (int i = 1; i <= 5; i++) {
      _homeTeam.addAthlete(
        AthleteStats(id: 'h_$i', name: 'Player $i', number: i),
      );
      _awayTeam.addAthlete(
        AthleteStats(id: 'a_$i', name: 'Player $i', number: i + 100),
      );
    }
  }

  // ==================== GAME CONTROL ====================

  void startGame() {
    _gameStatus = 'LIVE';
    _gameTime = Duration.zero;
    _currentPeriod = 1;
    notifyListeners();
  }

  void pauseGame() {
    _gameStatus = 'PAUSE';
    notifyListeners();
  }

  void resumeGame() {
    _gameStatus = 'LIVE';
    notifyListeners();
  }

  void endGame() {
    _gameStatus = 'END';
    notifyListeners();
  }

  void endPeriod() {
    _currentPeriod++;
    _gameTime = Duration.zero;
    notifyListeners();
  }

  void setGameTime(Duration time) {
    _gameTime = time;
    notifyListeners();
  }

  // ==================== SCORING & STATS ====================

  void addPoints(String teamId, String athleteId, int points) {
    final team = teamId == 'home' ? _homeTeam : _awayTeam;
    final athlete = team.athletes.firstWhere((a) => a.id == athleteId, orElse: () => throw Exception('Athlete not found'));
    
    athlete.points += points;
    _logEvent('${athlete.name} scored $points points', teamId);
    
    if (points >= 3) {
      _replayQueue.add('3-POINTER by ${athlete.name}');
    }
    
    notifyListeners();
  }

  void addRebound(String teamId, String athleteId) {
    final team = teamId == 'home' ? _homeTeam : _awayTeam;
    final athlete = team.athletes.firstWhere((a) => a.id == athleteId, orElse: () => throw Exception('Athlete not found'));
    
    athlete.rebounds++;
    _logEvent('${athlete.name} grabbed rebound', teamId);
    notifyListeners();
  }

  void addAssist(String teamId, String athleteId) {
    final team = teamId == 'home' ? _homeTeam : _awayTeam;
    final athlete = team.athletes.firstWhere((a) => a.id == athleteId, orElse: () => throw Exception('Athlete not found'));
    
    athlete.assists++;
    _logEvent('${athlete.name} got an assist', teamId);
    notifyListeners();
  }

  void addFoul(String teamId, String athleteId) {
    final team = teamId == 'home' ? _homeTeam : _awayTeam;
    final athlete = team.athletes.firstWhere((a) => a.id == athleteId, orElse: () => throw Exception('Athlete not found'));
    
    athlete.fouls++;
    if (athlete.fouls >= 6) {
      athlete.status = 'BENCH';
      _lastEventDescription = '${athlete.name} FOULED OUT!';
    } else {
      _logEvent('${athlete.name} committed foul (${athlete.fouls})', teamId);
    }
    notifyListeners();
  }

  void setFieldGoalPercentage(String teamId, String athleteId, double percentage) {
    final team = teamId == 'home' ? _homeTeam : _awayTeam;
    final athlete = team.athletes.firstWhere((a) => a.id == athleteId, orElse: () => throw Exception('Athlete not found'));
    
    athlete.fieldGoalPercentage = percentage.clamp(0.0, 100.0);
    notifyListeners();
  }

  // ==================== GRAPHICS OVERLAY ====================

  void toggleScoreboard() {
    _showScoreboard = !_showScoreboard;
    notifyListeners();
  }

  void toggleLowerThird(String text) {
    _showLowerThird = !_showLowerThird;
    _lowerThirdText = text;
    notifyListeners();
  }

  void toggleStatsOverlay() {
    _showStatsOverlay = !_showStatsOverlay;
    notifyListeners();
  }

  void setLowerThirdText(String text) {
    _lowerThirdText = text;
    notifyListeners();
  }

  // ==================== REPLAY SYSTEM ====================

  Future<void> triggerInstantReplay() async {
    if (_replayQueue.isNotEmpty) {
      _lastEventDescription = _replayQueue.removeAt(0);
      notifyListeners();
      
      await Future.delayed(const Duration(seconds: 5));
      notifyListeners();
    }
  }

  void clearReplayQueue() {
    _replayQueue.clear();
    notifyListeners();
  }

  // ==================== STATS & ANALYSIS ====================

  Map<String, dynamic> getGameStats() {
    return {
      'period': _currentPeriod,
      'gameTime': _gameTime.inSeconds,
      'homeTeam': {
        'name': _homeTeam.name,
        'totalPoints': _homeTeam.totalPoints,
        'totalRebounds': _homeTeam.totalRebounds,
        'totalAssists': _homeTeam.totalAssists,
        'fouls': _homeTeam.fouls,
      },
      'awayTeam': {
        'name': _awayTeam.name,
        'totalPoints': _awayTeam.totalPoints,
        'totalRebounds': _awayTeam.totalRebounds,
        'totalAssists': _awayTeam.totalAssists,
        'fouls': _awayTeam.fouls,
      },
    };
  }

  List<AthleteStats> getTopScorers({int limit = 5}) {
    final all = [..._homeTeam.athletes, ..._awayTeam.athletes];
    all.sort((a, b) => b.points.compareTo(a.points));
    return all.take(limit).toList();
  }

  List<AthleteStats> getTopRebounders({int limit = 5}) {
    final all = [..._homeTeam.athletes, ..._awayTeam.athletes];
    all.sort((a, b) => b.rebounds.compareTo(a.rebounds));
    return all.take(limit).toList();
  }

  // ==================== HELPERS ====================

  void _logEvent(String description, String teamId) {
    _lastEventDescription = description;
    _playLog.add({
      'timestamp': DateTime.now(),
      'team': teamId,
      'description': description,
      'period': _currentPeriod,
      'gameTime': _gameTime.inSeconds,
    });
  }

  void resetGame() {
    _homeTeam.score = 0;
    _awayTeam.score = 0;
    _currentPeriod = 1;
    _gameTime = Duration.zero;
    _gameStatus = 'PRE_GAME';
    _playLog.clear();
    _replayQueue.clear();
    _lastEventDescription = '';
    _initializeTeams();
    notifyListeners();
  }
}