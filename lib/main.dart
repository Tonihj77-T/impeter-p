import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await WordDatabase.loadWords();
  runApp(const MrWhiteApp());
}

class MrWhiteApp extends StatefulWidget {
  const MrWhiteApp({super.key});

  @override
  _MrWhiteAppState createState() => _MrWhiteAppState();
}

class _MrWhiteAppState extends State<MrWhiteApp> {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static _MrWhiteAppState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Mr. White',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardThemeData(
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            elevation: 8,
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF1E1E1E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            elevation: 8,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.deepPurple),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.deepPurple;
            }
            return Colors.grey;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.deepPurple.withOpacity(0.5);
            }
            return Colors.grey.withOpacity(0.3);
          }),
        ),
      ),
      themeMode: GameSettings.instance.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }

  static void restartApp() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  static void rebuildApp() {
    _instance?.rebuild();
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
  Map<String, String> customWordTips = {};
  bool isDarkMode = false;
  bool showTips = false;

  static GameSettings instance = GameSettings();

  Map<String, String> get texts => language == 'de' ? germanTexts : englishTexts;
}

enum GameMode { classic, places, words }
enum GamePhase { setup, roleReveal, discussion, voting, results }

// Custom page transitions
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final AxisDirection direction;

  SlidePageRoute({
    required this.child,
    this.direction = AxisDirection.right,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            const Offset end = Offset.zero;
            
            switch (direction) {
              case AxisDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case AxisDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
              case AxisDirection.left:
                begin = const Offset(1.0, 0.0);
                break;
              case AxisDirection.right:
                begin = const Offset(-1.0, 0.0);
                break;
            }

            final tween = Tween(begin: begin, end: end);
            final offsetAnimation = animation.drive(tween.chain(
              CurveTween(curve: Curves.easeInOutCubic),
            ));

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadePageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(
                CurveTween(curve: Curves.easeInOut),
              ),
              child: child,
            );
          },
        );
}

class Player {
  String name;
  bool isImposter;
  bool isEliminated;
  int voteCount;
  int wins;

  Player({
    required this.name,
    this.isImposter = false,
    this.isEliminated = false,
    this.voteCount = 0,
    this.wins = 0,
  });
}

class GameData {
  List<Player> players = [];
  List<String> persistentNames = [];
  int currentRound = 1;
  int currentPlayerIndex = 0;
  String currentWord = '';
  GamePhase phase = GamePhase.setup;
  Timer? gameTimer;
  int remainingSeconds = 0;
  Map<String, int> gameStatistics = {};
  Set<String> usedWords = {}; // Track used words to prevent repeats

  void reset() {
    // Store current names before clearing
    persistentNames = players.map((p) => p.name).toList();
    players.clear();
    currentRound = 1;
    currentPlayerIndex = 0;
    currentWord = '';
    phase = GamePhase.setup;
    gameTimer?.cancel();
    remainingSeconds = 0;
  }

  void addWinToPlayer(String playerName) {
    gameStatistics[playerName] = (gameStatistics[playerName] ?? 0) + 1;
  }

  void resetStatistics() {
    gameStatistics.clear();
    persistentNames.clear();
    // Also clear used words when resetting statistics
    usedWords.clear();
  }

  void markWordAsUsed(String word) {
    usedWords.add(word);
  }

  bool isWordUsed(String word) {
    return usedWords.contains(word);
  }

  static GameData instance = GameData();
}

// Wort-Datenbanken
class WordDatabase {
  static List<String> places = [];
  static List<String> words = [];
  static List<String> classic = [];
  static Map<String, String> tips = {};
  static bool _isLoaded = false;

  static Future<void> loadWords() async {
    if (_isLoaded) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/words.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      places = (data['places'] as List)
          .map((item) => item['word'] as String)
          .toList();
      
      words = (data['words'] as List)
          .map((item) => item['word'] as String)
          .toList();
      
      classic = [...places, ...words];
      
      // Load tips
      tips.clear();
      for (var item in data['places'] as List) {
        tips[item['word']] = item['tip'];
      }
      for (var item in data['words'] as List) {
        tips[item['word']] = item['tip'];
      }
      
      _isLoaded = true;
    } catch (e) {
      // Fallback to hardcoded words if JSON loading fails
      places = [
        'Berlin', 'Paris', 'London', 'New York', 'Tokio', 'Rom', 'Madrid', 'Amsterdam',
        'Wien', 'Zürich', 'Moskau', 'Sydney', 'Kairo', 'Bangkok', 'Mumbai', 'Shanghai'
      ];
      words = [
        'Apfel', 'Auto', 'Hund', 'Computer', 'Blume', 'Buch', 'Stuhl', 'Telefon',
        'Kamera', 'Gitarre', 'Pizza', 'Schokolade', 'Regenschirm', 'Brille', 'Schlüssel'
      ];
      classic = [...places, ...words];
      
      // Fallback tips
      tips = {
        'Berlin': 'Deutsche Großstadt',
        'Paris': 'Europäische Hauptstadt',
        'London': 'Inselstaat-Zentrum',
        'New York': 'Amerikanische Metropole',
        'Tokio': 'Asiatische Millionenstadt',
        'Rom': 'Antike Hauptstadt',
        'Madrid': 'Iberische Halbinsel',
        'Amsterdam': 'Niederlande',
        'Wien': 'Österreich',
        'Zürich': 'Schweiz',
        'Moskau': 'Osteuropäische Großstadt',
        'Sydney': 'Südhalbkugel',
        'Kairo': 'Nordafrikanische Stadt',
        'Bangkok': 'Südostasien',
        'Mumbai': 'Südasiatische Küstenstadt',
        'Shanghai': 'Ostasiatischer Hafen',
        'Apfel': 'Obst',
        'Auto': 'Fortbewegungsmittel',
        'Hund': 'Haustier',
        'Computer': 'Technisches Gerät',
        'Blume': 'Pflanze',
        'Buch': 'Lesematerial',
        'Stuhl': 'Möbelstück',
        'Telefon': 'Kommunikationsgerät',
        'Kamera': 'Optisches Gerät',
        'Gitarre': 'Musikinstrument',
        'Pizza': 'Italienisches Gericht',
        'Schokolade': 'Süßware',
        'Regenschirm': 'Wetterschutz',
        'Brille': 'Sehhilfe',
        'Schlüssel': 'Öffnungsgerät',
      };
      _isLoaded = true;
    }
  }

  static String getTip(String word) {
    // Check custom tips first
    if (GameSettings.instance.customWordTips.containsKey(word)) {
      return GameSettings.instance.customWordTips[word]!;
    }
    // Then check standard tips
    return tips[word] ?? 'Kein Tipp verfügbar';
  }
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
  'needsAllPlayers': 'Alle Spielerplätze müssen besetzt sein!',
  'statistics': 'Statistik',
  'wins': 'Siege',
  'resetStatistics': 'Statistik zurücksetzen',
  'noGamesPlayed': 'Noch keine Spiele gespielt.',
  'darkMode': 'Dunkler Modus',
  'showTips': 'Tipps anzeigen',
  'tip': 'Tipp:',
  'tapToReveal': 'Tippe zum Aufdecken',
  'addCustomWord': 'Eigenes Wort hinzufügen',
  'customWordsList': 'Eigene Wörter',
  'deleteWord': 'Wort löschen'
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
  'needsAllPlayers': 'All player slots must be filled!',
  'statistics': 'Statistics',
  'wins': 'Wins',
  'resetStatistics': 'Reset Statistics',
  'noGamesPlayed': 'No games played yet.',
  'darkMode': 'Dark Mode',
  'showTips': 'Show Tips',
  'tip': 'Tip:',
  'tapToReveal': 'Tap to Reveal',
  'addCustomWord': 'Add Custom Word',
  'customWordsList': 'Custom Words',
  'deleteWord': 'Delete Word'
};

// Haupt-Screens
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 0.1,
                        child: Icon(
                          Icons.group,
                          size: 120,
                          color: Colors.deepPurple.withOpacity(value),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  _AnimatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      SlidePageRoute(child: const GameScreen()),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(texts['startGame']!),
                    isPrimary: true,
                  ),
                  const SizedBox(height: 16),
                  _AnimatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      SlidePageRoute(child: const SettingsScreen(), direction: AxisDirection.up),
                    ),
                    icon: const Icon(Icons.settings),
                    label: Text(texts['settings']!),
                  ),
                  const SizedBox(height: 16),
                  _AnimatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      FadePageRoute(child: const StatisticsScreen()),
                    ),
                    icon: const Icon(Icons.bar_chart),
                    label: Text(texts['statistics']!),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;
  final bool isPrimary;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isPrimary = false,
  });

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.isPrimary
          ? ElevatedButton.icon(
              onPressed: () {
                _controller.forward().then((_) {
                  _controller.reverse();
                  widget.onPressed();
                });
              },
              icon: widget.icon,
              label: widget.label,
            )
          : OutlinedButton.icon(
              onPressed: () {
                _controller.forward().then((_) {
                  _controller.reverse();
                  widget.onPressed();
                });
              },
              icon: widget.icon,
              label: widget.label,
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
  final _customWordController = TextEditingController();
  final _customTipController = TextEditingController();

  void _addCustomWord() {
    if (_customWordController.text.trim().isEmpty) return;
    final word = _customWordController.text.trim();
    final tip = _customTipController.text.trim();
    
    setState(() {
      settings.customWords.add(word);
      if (tip.isNotEmpty) {
        settings.customWordTips[word] = tip;
      }
      _customWordController.clear();
      _customTipController.clear();
    });
  }

  void _removeCustomWord(int index) {
    setState(() {
      final word = settings.customWords[index];
      settings.customWords.removeAt(index);
      settings.customWordTips.remove(word);
    });
  }

  void _showAddWordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settings.texts['addCustomWord']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customWordController,
              decoration: InputDecoration(
                labelText: 'Wort',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customTipController,
              decoration: InputDecoration(
                labelText: 'Tipp (optional)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _customWordController.clear();
              _customTipController.clear();
              Navigator.pop(context);
            },
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              _addCustomWord();
              Navigator.pop(context);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = settings.texts;
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['settings']!),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${texts['playerCount']} ${settings.playerCount}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${texts['roundCount']} ${settings.roundCount}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${texts['timerMinutes']} ${settings.timerMinutes}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sprache / Language',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: settings.language,
                    isExpanded: true,
                    items: const [
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spielmodus / Game Mode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texts['darkMode']!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: Text(texts['darkMode']!),
                    value: settings.isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        settings.isDarkMode = value;
                      });
                      // Rebuild the entire app to apply theme change
                      _MrWhiteAppState.rebuildApp();
                    },
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texts['showTips']!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: Text(texts['showTips']!),
                    subtitle: const Text('Imposter bekommt Hinweise zum Wort'),
                    value: settings.showTips,
                    onChanged: (value) {
                      setState(() {
                        settings.showTips = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texts['customWordsList']!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _showAddWordDialog,
                    icon: const Icon(Icons.add),
                    label: Text(texts['addCustomWord']!),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (settings.customWords.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Eigene Wörter:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...settings.customWords.asMap().entries.map((entry) {
                          final index = entry.key;
                          final word = entry.value;
                          final tip = settings.customWordTips[word];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                child: Text('${index + 1}'),
                              ),
                              title: Text(word),
                              subtitle: tip != null ? Text('Tipp: $tip') : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeCustomWord(index),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                SlidePageRoute(child: const GameScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(texts['startGame']!),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customWordController.dispose();
    _customTipController.dispose();
    super.dispose();
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameData _gameData = GameData.instance;
  final _playerNameController = TextEditingController();
  bool _isCardFlipped = false;

  @override
  void initState() {
    super.initState();
    _loadPersistentPlayers();
  }

  void _loadPersistentPlayers() {
    _gameData.players.clear();
    for (String name in _gameData.persistentNames) {
      if (_gameData.players.length < GameSettings.instance.playerCount) {
        _gameData.players.add(Player(name: name));
      }
    }
  }

  String _selectUnusedWord(List<String> wordPool, Random rand) {
    // First try to find unused words
    List<String> unusedWords = wordPool.where((word) => !_gameData.isWordUsed(word)).toList();
    
    if (unusedWords.isNotEmpty) {
      // Select from unused words
      return unusedWords[rand.nextInt(unusedWords.length)];
    } else {
      // If all words have been used, reset and select any word
      // Clear used words for this specific pool to start fresh
      for (String word in wordPool) {
        _gameData.usedWords.remove(word);
      }
      return wordPool[rand.nextInt(wordPool.length)];
    }
  }

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

    // Select word with 25% chance for custom words if available, avoiding repeats
    List<String> standardPool;
    switch (settings.gameMode) {
      case GameMode.places:
        standardPool = WordDatabase.places;
        break;
      case GameMode.words:
        standardPool = WordDatabase.words;
        break;
      default:
        standardPool = WordDatabase.classic;
    }
    
    String selectedWord;
    
    if (settings.customWords.isNotEmpty && rand.nextDouble() < 0.25) {
      // 25% chance to select from custom words
      selectedWord = _selectUnusedWord(settings.customWords, rand);
    } else {
      // 75% chance to select from standard pool
      selectedWord = _selectUnusedWord(standardPool, rand);
    }
    
    _gameData.currentWord = selectedWord;
    _gameData.markWordAsUsed(selectedWord);

    // Set timer
    if (settings.timerMinutes > 0) {
      _gameData.remainingSeconds = settings.timerMinutes * 60;
    }

    setState(() {
      _gameData.phase = GamePhase.roleReveal;
      _gameData.currentPlayerIndex = 0;
      _isCardFlipped = false;
    });
  }

  void _nextPlayer() {
    setState(() {
      _isCardFlipped = false;
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
      
      // Track win: if imposter eliminated, all non-imposters win, otherwise imposter wins
      if (eliminated.isImposter) {
        for (var player in _gameData.players.where((p) => !p.isImposter)) {
          _gameData.addWinToPlayer(player.name);
        }
      } else {
        final imposter = _gameData.players.firstWhere((p) => p.isImposter);
        _gameData.addWinToPlayer(imposter.name);
      }
    });
  }

  void _nextRound() {
    if (_gameData.currentRound < GameSettings.instance.roundCount) {
      setState(() {
        _gameData.currentRound++;
        _gameData.phase = GamePhase.setup;
      });
    } else {
      Navigator.push(
        context,
        FadePageRoute(child: const FinalStatisticsScreen()),
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
    final settings = GameSettings.instance;
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
            colors: _isCardFlipped
                ? (player.isImposter
                    ? [Colors.red.shade100, Colors.red.shade50]
                    : [Colors.green.shade100, Colors.green.shade50])
                : [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCardFlipped = true;
                    });
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: Curves.elasticOut)
                        ),
                        child: child,
                      );
                    },
                    child: _isCardFlipped
                        ? _buildRevealedCard(player, texts, settings)
                        : _buildHiddenCard(texts),
                  ),
                ),
                const SizedBox(height: 40),
                if (_isCardFlipped)
                  ElevatedButton.icon(
                    onPressed: _nextPlayer,
                    icon: Icon(isLast ? Icons.play_arrow : Icons.navigate_next),
                    label: Text(
                      isLast ? texts['discussion']! : texts['next']!,
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHiddenCard(Map<String, String> texts) {
    return Card(
      key: const ValueKey('hidden'),
      elevation: 12,
      child: Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.touch_app,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              texts['tapToReveal']!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealedCard(Player player, Map<String, String> texts, GameSettings settings) {
    String tipText = '';
    if (settings.showTips && player.isImposter) {
      tipText = WordDatabase.getTip(_gameData.currentWord);
    }

    return Card(
      key: const ValueKey('revealed'),
      elevation: 12,
      child: Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: player.isImposter
                ? [Colors.red.shade300, Colors.red.shade600]
                : [Colors.green.shade300, Colors.green.shade600],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                player.isImposter ? Icons.warning : Icons.check_circle,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                player.isImposter
                    ? texts['youAreImposter']!
                    : '${texts['youAreNot']} ${_gameData.currentWord}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (settings.showTips && player.isImposter && tipText.isNotEmpty) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        texts['tip']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tipText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        FadePageRoute(child: const FinalStatisticsScreen()),
                      );
                    },
                    icon: const Icon(Icons.bar_chart),
                    label: Text(
                      texts['statistics']!,
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = GameSettings.instance.texts;
    final gameData = GameData.instance;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['statistics']!),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (gameData.gameStatistics.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    texts['noGamesPlayed']!,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: gameData.gameStatistics.length,
                  itemBuilder: (_, index) {
                    final entry = gameData.gameStatistics.entries.elementAt(index);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(entry.key),
                        trailing: Text(
                          '${entry.value} ${texts['wins']!}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (gameData.gameStatistics.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(texts['resetStatistics']!),
                        content: const Text('Möchten Sie wirklich alle Statistiken zurücksetzen?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Abbrechen'),
                          ),
                          TextButton(
                            onPressed: () {
                              gameData.resetStatistics();
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('Zurücksetzen'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(texts['resetStatistics']!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FinalStatisticsScreen extends StatelessWidget {
  const FinalStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = GameSettings.instance.texts;
    final gameData = GameData.instance;
    
    // Sort statistics by wins (descending)
    final sortedStats = gameData.gameStatistics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['gameOver']!),
        automaticallyImplyLeading: false,
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 20),
              Text(
                texts['statistics']!,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (sortedStats.isEmpty)
                const Text(
                  'Keine Statistiken verfügbar',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedStats.length,
                    itemBuilder: (_, index) {
                      final entry = sortedStats[index];
                      final isWinner = index == 0;
                      return Card(
                        elevation: isWinner ? 12 : 4,
                        color: isWinner ? Colors.amber.shade100 : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isWinner ? Colors.amber : Colors.deepPurple,
                            foregroundColor: Colors.white,
                            child: isWinner
                                ? const Icon(Icons.emoji_events)
                                : Text('${index + 1}'),
                          ),
                          title: Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                              fontSize: isWinner ? 18 : 16,
                            ),
                          ),
                          trailing: Text(
                            '${entry.value} ${texts['wins']!}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isWinner ? 18 : 16,
                              color: isWinner ? Colors.amber.shade800 : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    gameData.reset();
                    _MrWhiteAppState.restartApp();
                  },
                  icon: const Icon(Icons.home),
                  label: Text(
                    texts['newGame']!,
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}