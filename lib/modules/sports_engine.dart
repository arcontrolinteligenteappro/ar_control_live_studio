// FILE: lib/modules/sports_engine.dart
import 'package:flutter/foundation.dart';

class SportsEngine extends ChangeNotifier {
  String homeName = "LOCAL";
  String awayName = "VISITA";
  int homeScore = 0;
  int awayScore = 0;
  int period = 1;
  int foulsHome = 0;
  int foulsAway = 0;
  String sportType = "GENERAL";

  void setupSport(String sport) {
    sportType = sport;
    homeScore = 0;
    awayScore = 0;
    period = 1;
    foulsHome = 0;
    foulsAway = 0;
    notifyListeners();
  }

  void addHome(int pts) { homeScore += pts; notifyListeners(); }
  void subHome(int pts) { if (homeScore >= pts) homeScore -= pts; notifyListeners(); }
  
  void addAway(int pts) { awayScore += pts; notifyListeners(); }
  void subAway(int pts) { if (awayScore >= pts) awayScore -= pts; notifyListeners(); }

  void addFoulHome() { foulsHome++; notifyListeners(); }
  void addFoulAway() { foulsAway++; notifyListeners(); }

  void nextPeriod() {
    if (sportType == "SOCCER" && period < 2) period++;
    if (sportType == "BASKETBALL" && period < 4) period++;
    notifyListeners();
  }

  // CORRECCIÓN: Nombre unificado para la interfaz de usuario
  void resetScore() {
    homeScore = 0;
    awayScore = 0;
    period = 1;
    foulsHome = 0;
    foulsAway = 0;
    notifyListeners();
  }
}