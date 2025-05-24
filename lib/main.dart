import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
void main() {
  runApp(MrWhiteApp());
}

class MrWhiteApp extends StatelessWidget {
  const MrWhiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mr. White',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardThemeData(
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            elevation: 8,
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

// Datenmodelle
class GameSettings {
  int playerCount = 5;
  int roundCount = 1;
  int timerMinutes = 0;
  String language = 'de';
  GameMode gameMode = GameMode.classic;
  List<String> customWords = [];

  static GameSettings instance = GameSettings();

  Map<String, String> get texts => language == 'de' ? germanTexts : englishTexts;
}

enum GameMode { classic, places, words }
enum GamePhase { setup, roleReveal, discussion, voting, results }

class Player {
  String name;
  bool isImposter;
  bool isEliminated;
  int voteCount;

  Player({
    required this.name,
    this.isImposter = false,
    this.isEliminated = false,
    this.voteCount = 0,
  });
}

class GameData {
  List<Player> players = [];
  int currentRound = 1;
  int currentPlayerIndex = 0;
  String currentWord = '';
  GamePhase phase = GamePhase.setup;
  Timer? gameTimer;
  int remainingSeconds = 0;

  void reset() {
    players.clear();
    currentRound = 1;
    currentPlayerIndex = 0;
    currentWord = '';
    phase = GamePhase.setup;
    gameTimer?.cancel();
    remainingSeconds = 0;
  }
}

// Wort-Datenbanken
class WordDatabase {
  static const places = [
    'Berlin', 'Paris', 'London', 'New York', 'Tokio', 'Rom', 'Madrid', 'Amsterdam',
    'Wien', 'Zürich', 'Moskau', 'Sydney', 'Kairo', 'Bangkok', 'Mumbai', 'Shanghai'
  ];

  static const words = [
    'Apfel', 'Auto', 'Hund', 'Computer', 'Blume', 'Buch', 'Stuhl', 'Telefon',
    'Kamera', 'Gitarre', 'Pizza', 'Schokolade', 'Regenschirm', 'Brille', 'Schlüssel'
  ];

  static const classic = [...places, ...words];
}

// Übersetzungen
const Map<String, String> germanTexts = {
  'homeTitle': 'Mr. White',
  'startGame': 'Neues Spiel',
  'settings': 'Einstellungen',
  'playerSetup': 'Spieler hinzufügen',
  'enterName': 'Name eingeben',
  'add': 'Hinzufügen',
  'remove': 'Entfernen',
  'startRound': 'Spiel starten',
  'roleReveal': 'Rolle enthüllen',
  'youAreImposter': 'Du bist der Impostor!',
  'youAreNot': 'Du bist kein Impostor. Wort:',
  'next': 'Weiter',
  'discussion': 'Diskussion',
  'vote': 'Abstimmung',
  'confirm': 'Bestätigen',
  'results': 'Ergebnis',
  'eliminated': 'wurde eliminiert!',
  'wasImposter': 'Er war der Impostor!',
  'wasNotImposter': 'Er war nicht der Impostor!',
  'nextRound': 'Nächste Runde',
  'gameOver': 'Spiel vorbei',
  'finalResults': 'Das Spiel ist zu Ende.',
  'newGame': 'Neues Spiel',
  'timeRemaining': 'Zeit übrig:',
  'selectPlayer': 'Wähle den Spieler aus, der eliminiert werden soll:',
  'voteFor': 'Wählen',
  'votes': 'Stimmen:',
  'wordWas': 'Das Wort war:',
  'playerCount': 'Spieleranzahl:',
  'roundCount': 'Rundenanzahl:',
  'timerMinutes': 'Timer (Minuten):',
  'customWords': 'Eigene Wörter (Komma getrennt)',
  'needsAllPlayers': 'Alle Spielerplätze müssen besetzt sein!'
};

const Map<String, String> englishTexts = {
  'homeTitle': 'Mr. White',
  'startGame': 'New Game',
  'settings': 'Settings',
  'playerSetup': 'Add Players',
  'enterName': 'Enter Name',
  'add': 'Add',
  'remove': 'Remove',
  'startRound': 'Start Game',
  'roleReveal': 'Reveal Role',
  'youAreImposter': 'You are the Imposter!',
  'youAreNot': 'You are not the Imposter. Word:',
  'next': 'Next',
  'discussion': 'Discussion',
  'vote': 'Vote',
  'confirm': 'Confirm',
  'results': 'Results',
  'eliminated': 'was eliminated!',
  'wasImposter': 'They were the Imposter!',
  'wasNotImposter': 'They were not the Imposter!',
  'nextRound': 'Next Round',
  'gameOver': 'Game Over',
  'finalResults': 'The game has ended.',
  'newGame': 'New Game',
  'timeRemaining': 'Time remaining:',
  'selectPlayer': 'Select the player to eliminate:',
  'voteFor': 'Vote',
  'votes': 'Votes:',
  'wordWas': 'The word was:',
  'playerCount': 'Player Count:',
  'roundCount': 'Round Count:',
  'timerMinutes': 'Timer (Minutes):',
  'customWords': 'Custom Words (comma separated)',
  'needsAllPlayers': 'All player slots must be filled!'
};

// Haupt-Screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = GameSettings.instance.texts;
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['homeTitle']!),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group,
                size: 120,
                color: Colors.deepPurple,
              ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen()),
                ),
                icon: Icon(Icons.play_arrow),
                label: Text(texts['startGame']!),
              ),
              SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen()),
                ),
                icon: Icon(Icons.settings),
                label: Text(texts['settings']!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settings = GameSettings.instance;
  final _customController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final texts = settings.texts;
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['settings']!),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${texts['playerCount']} ${settings.playerCount}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    min: 3,
                    max: 10,
                    divisions: 7,
                    value: settings.playerCount.toDouble(),
                    label: settings.playerCount.toString(),
                    onChanged: (v) => setState(() {
                      settings.playerCount = v.toInt();
                    }),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${texts['roundCount']} ${settings.roundCount}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    min: 1,
                    max: 10,
                    divisions: 9,
                    value: settings.roundCount.toDouble(),
                    label: settings.roundCount.toString(),
                    onChanged: (v) => setState(() {
                      settings.roundCount = v.toInt();
                    }),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${texts['timerMinutes']} ${settings.timerMinutes}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    min: 0,
                    max: 10,
                    divisions: 10,
                    value: settings.timerMinutes.toDouble(),
                    label: settings.timerMinutes.toString(),
                    onChanged: (v) => setState(() {
                      settings.timerMinutes = v.toInt();
                    }),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sprache / Language',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    value: settings.language,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (v) => setState(() {
                      settings.language = v!;
                    }),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spielmodus / Game Mode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButton<GameMode>(
                    value: settings.gameMode,
                    isExpanded: true,
                    items: GameMode.values.map((mode) {
                      String displayName;
                      switch (mode) {
                        case GameMode.classic:
                          displayName = 'Classic';
                          break;
                        case GameMode.places:
                          displayName = 'Places';
                          break;
                        case GameMode.words:
                          displayName = 'Words';
                          break;
                      }
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(displayName),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() {
                      settings.gameMode = v!;
                    }),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texts['customWords']!,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _customController,
                    decoration: InputDecoration(
                      labelText: texts['customWords'],
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              settings.customWords = _customController.text
                  .split(',')
                  .map((w) => w.trim())
                  .where((w) => w.isNotEmpty)
                  .toList();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => GameScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(texts['startGame']!),
          ),
        ],
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameData _gameData = GameData();
  final _playerNameController = TextEditingController();

  void _addPlayer() {
    if (_playerNameController.text.trim().isEmpty) return;
    if (_gameData.players.length < GameSettings.instance.playerCount) {
      setState(() {
        _gameData.players.add(Player(name: _playerNameController.text.trim()));
        _playerNameController.clear();
      });
    }
  }

  void _removePlayer(int idx) {
    setState(() {
      _gameData.players.removeAt(idx);
    });
  }

  void _startRound() {
    final settings = GameSettings.instance;

    // Reset all players
    for (var p in _gameData.players) {
      p.isImposter = false;
      p.voteCount = 0;
      p.isEliminated = false;
    }

    // Assign impostor
    final rand = Random();
    int impIdx = rand.nextInt(_gameData.players.length);
    _gameData.players[impIdx].isImposter = true;

    // Select word
    List<String> pool;
    switch (settings.gameMode) {
      case GameMode.places:
        pool = WordDatabase.places;
        break;
      case GameMode.words:
        pool = WordDatabase.words;
        break;
      default:
        pool = WordDatabase.classic;
    }
    pool = [...pool, ...settings.customWords];
    _gameData.currentWord = pool[rand.nextInt(pool.length)];

    // Set timer
    if (settings.timerMinutes > 0) {
      _gameData.remainingSeconds = settings.timerMinutes * 60;
    }

    setState(() {
      _gameData.phase = GamePhase.roleReveal;
      _gameData.currentPlayerIndex = 0;
    });
  }

  void _nextPlayer() {
    setState(() {
      if (_gameData.currentPlayerIndex < _gameData.players.length - 1) {
        _gameData.currentPlayerIndex++;
      } else {
        _startDiscussion();
      }
    });
  }

  void _startDiscussion() {
    setState(() {
      _gameData.phase = GamePhase.discussion;
    });
    if (GameSettings.instance.timerMinutes > 0) {
      _gameData.gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_gameData.remainingSeconds > 0) {
          setState(() => _gameData.remainingSeconds--);
        } else {
          timer.cancel();
          _startVoting();
        }
      });
    }
  }

  void _startVoting() {
    _gameData.gameTimer?.cancel();
    setState(() {
      _gameData.phase = GamePhase.voting;
      for (var p in _gameData.players) {
        p.voteCount = 0;
      }
    });
  }

  void _castVote(Player target) {
    setState(() {
      target.voteCount++;
    });
  }

  void _finishVoting() {
    final eliminated = _gameData.players.reduce((a, b) => a.voteCount >= b.voteCount ? a : b);
    setState(() {
      eliminated.isEliminated = true;
      _gameData.phase = GamePhase.results;
    });
  }

  void _nextRound() {
    if (_gameData.currentRound < GameSettings.instance.roundCount) {
      setState(() {
        _gameData.currentRound++;
        _gameData.phase = GamePhase.setup;
      });
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(GameSettings.instance.texts['gameOver']!),
          content: Text(GameSettings.instance.texts['finalResults']!),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
                _gameData.reset();
              },
              child: Text(GameSettings.instance.texts['newGame']!),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_gameData.phase) {
      case GamePhase.setup:
        return _buildPlayerSetup();
      case GamePhase.roleReveal:
        return _buildRoleReveal();
      case GamePhase.discussion:
        return _buildDiscussion();
      case GamePhase.voting:
        return _buildVoting();
      case GamePhase.results:
        return _buildResults();
    }
  }

  Widget _buildPlayerSetup() {
    final texts = GameSettings.instance.texts;
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['playerSetup']!),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Runde ${_gameData.currentRound} von ${GameSettings.instance.roundCount}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Spieler: ${_gameData.players.length}/${GameSettings.instance.playerCount}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _playerNameController,
              decoration: InputDecoration(
                labelText: texts['enterName'],
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addPlayer,
                ),
              ),
              onSubmitted: (_) => _addPlayer(),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _gameData.players.length,
                itemBuilder: (_, idx) {
                  final p = _gameData.players[idx];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        child: Text('${idx + 1}'),
                      ),
                      title: Text(p.name),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removePlayer(idx),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _gameData.players.length == GameSettings.instance.playerCount
                    ? _startRound
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _gameData.players.length == GameSettings.instance.playerCount
                      ? texts['startRound']!
                      : texts['needsAllPlayers']!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleReveal() {
    final texts = GameSettings.instance.texts;
    final player = _gameData.players[_gameData.currentPlayerIndex];
    final isLast = _gameData.currentPlayerIndex == _gameData.players.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(texts['roleReveal']!),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: player.isImposter
                ? [Colors.red.shade100, Colors.red.shade50]
                : [Colors.green.shade100, Colors.green.shade50],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  player.isImposter ? Icons.warning : Icons.check_circle,
                  size: 80,
                  color: player.isImposter ? Colors.red : Colors.green,
                ),
                SizedBox(height: 20),
                Text(
                  player.name,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      player.isImposter
                          ? texts['youAreImposter']!
                          : '${texts['youAreNot']} ${_gameData.currentWord}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: player.isImposter ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _nextPlayer,
                  icon: Icon(isLast ? Icons.play_arrow : Icons.navigate_next),
                  label: Text(
                    isLast ? texts['discussion']! : texts['next']!,
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussion() {
    final texts = GameSettings.instance.texts;
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['discussion']!),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.forum,
                  size: 80,
                  color: Colors.blue,
                ),
                SizedBox(height: 20),
                if (GameSettings.instance.timerMinutes > 0)
                  Card(
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            texts['timeRemaining']!,
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '${(_gameData.remainingSeconds / 60).floor()}:${(_gameData.remainingSeconds % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: _gameData.remainingSeconds < 60 ? Colors.red : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 30),
                Text(
                  texts['discussion']!,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Diskutiert über verdächtige Personen!',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _startVoting,
                  icon: Icon(Icons.how_to_vote),
                  label: Text(
                    texts['vote']!,
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoting() {
    final texts = GameSettings.instance.texts;
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['vote']!),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  texts['selectPlayer']!,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _gameData.players.where((p) => !p.isEliminated).length,
                itemBuilder: (_, idx) {
                  final activePlayers = _gameData.players.where((p) => !p.isEliminated).toList();
                  final player = activePlayers[idx];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        child: Text('${_gameData.players.indexOf(player) + 1}'),
                      ),
                      title: Text(
                        player.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${texts['votes']} ${player.voteCount}'),
                      trailing: ElevatedButton(
                        onPressed: () => _castVote(player),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(texts['voteFor']!),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _finishVoting,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  texts['confirm']!,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final texts = GameSettings.instance.texts;
    final eliminated = _gameData.players.firstWhere((p) => p.isEliminated);

    return Scaffold(
      appBar: AppBar(
        title: Text(texts['results']!),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,end: Alignment.bottomCenter,
            colors: eliminated.isImposter
                ? [Colors.green.shade100, Colors.green.shade50]
                : [Colors.orange.shade100, Colors.orange.shade50],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  eliminated.isImposter ? Icons.check_circle : Icons.error,
                  size: 80,
                  color: eliminated.isImposter ? Colors.green : Colors.orange,
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          '${eliminated.name} ${texts['eliminated']!}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          eliminated.isImposter
                              ? texts['wasImposter']!
                              : texts['wasNotImposter']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: eliminated.isImposter ? Colors.green : Colors.orange,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        Text(
                          '${texts['wordWas']} ${_gameData.currentWord}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                if (_gameData.currentRound < GameSettings.instance.roundCount)
                  ElevatedButton.icon(
                    onPressed: _nextRound,
                    icon: Icon(Icons.navigate_next),
                    label: Text(
                      texts['nextRound']!,
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      _gameData.reset();
                    },
                    icon: Icon(Icons.home),
                    label: Text(
                      texts['newGame']!,
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameData.gameTimer?.cancel();
    _playerNameController.dispose();
    super.dispose();
  }
}