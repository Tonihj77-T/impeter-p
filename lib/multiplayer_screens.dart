import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math' as Math;
import 'main.dart';
import 'multiplayer_service.dart';

class MultiplayerMenuScreen extends StatefulWidget {
  const MultiplayerMenuScreen({super.key});

  @override
  _MultiplayerMenuScreenState createState() => _MultiplayerMenuScreenState();
}

class _MultiplayerMenuScreenState extends State<MultiplayerMenuScreen> {
  final _nameController = TextEditingController();
  final _lobbyCodeController = TextEditingController();
  late final MultiplayerService _multiplayerService;

  @override
  void initState() {
    super.initState();
    _multiplayerService = MultiplayerService();
    _multiplayerService.initialize();
    _multiplayerService.onError = (message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mehrspieler'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                : [Colors.deepPurple.shade100, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.people,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Dein Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _createLobby(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Lobby erstellen', style: TextStyle(fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lobbyCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Lobby-Code',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _joinLobby(),
                              icon: const Icon(Icons.login, size: 16),
                              label: const Text('Beitreten', style: TextStyle(fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _scanQRCode(),
                              icon: const Icon(Icons.qr_code_scanner, size: 16),
                              label: const Text('QR Code', style: TextStyle(fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _multiplayerService,
                builder: (context, child) {
                  if (_multiplayerService.isConnecting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Verbinde mit Server...'),
                          ],
                        ),
                      ),
                    );
                  } else if (_multiplayerService.isConnected) {
                    return const Card(
                      color: Colors.green,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Mit Server verbunden',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const Card(
                      color: Colors.orange,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Offline - Verbindung wird versucht...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createLobby() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib deinen Namen ein')),
      );
      return;
    }

    _multiplayerService.onLobbyCreated = (lobbyId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyScreen(
            lobbyId: lobbyId,
            playerName: _nameController.text.trim(),
            isHost: true,
          ),
        ),
      );
    };

    _multiplayerService.createLobby(_nameController.text.trim());
  }

  void _joinLobby() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib deinen Namen ein')),
      );
      return;
    }

    if (_lobbyCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Lobby-Code ein')),
      );
      return;
    }

    _multiplayerService.onPlayerJoined = (player) {
      if (player.name == _nameController.text.trim()) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              lobbyId: _lobbyCodeController.text.trim().toUpperCase(),
              playerName: _nameController.text.trim(),
              isHost: false,
            ),
          ),
        );
      }
    };

    _multiplayerService.joinLobby(
      _lobbyCodeController.text.trim().toUpperCase(),
      _nameController.text.trim(),
    );
  }

  void _scanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onCodeScanned: (code) {
            _lobbyCodeController.text = code;
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lobbyCodeController.dispose();
    super.dispose();
  }
}

class QRScannerScreen extends StatefulWidget {
  final Function(String) onCodeScanned;

  const QRScannerScreen({super.key, required this.onCodeScanned});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby-Code eingeben'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 24),
            const Text(
              'QR-Scanner momentan nicht verfügbar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bitte gib den Lobby-Code manuell ein:',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Lobby-Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
              onSubmitted: (value) => _submitCode(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitCode,
                icon: const Icon(Icons.check),
                label: const Text('Code übernehmen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitCode() {
    if (_codeController.text.trim().isNotEmpty) {
      widget.onCodeScanned(_codeController.text.trim().toUpperCase());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}

class LobbyScreen extends StatefulWidget {
  final String lobbyId;
  final String playerName;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.lobbyId,
    required this.playerName,
    required this.isHost,
  });

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late final MultiplayerService _multiplayerService;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isReady = false;
  bool _showQR = false;
  bool _showSettings = false;
  
  // Game Settings für Host
  int _impeterCount = 1;
  int _timerMinutes = 5;
  bool _showTips = true;

  @override
  void initState() {
    super.initState();
    _multiplayerService = MultiplayerService();
    _setupListeners();
  }

  void _setupListeners() {
    _multiplayerService.onPlayerJoined = (player) {
      setState(() {}); // Refresh UI
    };

    _multiplayerService.onPlayerLeft = (socketId) {
      setState(() {}); // Refresh UI
    };

    _multiplayerService.onPlayerReadyChanged = (socketId, ready) {
      setState(() {}); // Refresh UI
    };

    _multiplayerService.onGameStarted = () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerGameScreen(
            lobbyId: widget.lobbyId,
            playerName: widget.playerName,
          ),
        ),
      );
    };

    _multiplayerService.onChatMessage = (message) {
      setState(() {});
      _scrollToBottom();
    };

    _multiplayerService.onError = (message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    };
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lobby: ${widget.lobbyId}'),
        centerTitle: true,
        actions: [
          if (widget.isHost)
            IconButton(
              icon: Icon(_showSettings ? Icons.close : Icons.settings),
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
            ),
          IconButton(
            icon: Icon(_showQR ? Icons.people : Icons.qr_code),
            onPressed: () {
              setState(() {
                _showQR = !_showQR;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Lobby info
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _showSettings && widget.isHost 
                ? _buildSettings() 
                : (_showQR ? _buildQRCode() : _buildPlayerList()),
            ),
          ),
          
          // Chat section
          Expanded(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Chat',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _multiplayerService,
                      builder: (context, child) {
                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: _multiplayerService.chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = _multiplayerService.chatMessages[index];
                            final isOwnMessage = message.playerName == widget.playerName;
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 3,
                              ),
                              child: Row(
                                mainAxisAlignment: isOwnMessage
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOwnMessage
                                          ? Colors.deepPurple
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isOwnMessage)
                                          Text(
                                            message.playerName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        Text(
                                          message.message,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isOwnMessage
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: const InputDecoration(
                              hintText: 'Nachricht eingeben...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Ready button
          if (!widget.isHost)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isReady = !_isReady;
                    });
                    _multiplayerService.setPlayerReady(_isReady);
                  },
                  icon: Icon(_isReady ? Icons.check : Icons.schedule, size: 18),
                  label: Text(
                    _isReady ? 'Bereit!' : 'Bereit machen',
                    style: const TextStyle(fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isReady ? Colors.green : null,
                    foregroundColor: _isReady ? Colors.white : null,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          
          // Start game button (host only)
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: AnimatedBuilder(
                animation: _multiplayerService,
                builder: (context, child) {
                  final canStart = _multiplayerService.lobbyPlayers.length >= 3 &&
                      _multiplayerService.lobbyPlayers
                          .where((p) => !p.isHost)
                          .every((p) => p.isReady);
                  
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: canStart ? _startGame : null,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(
                        canStart 
                            ? 'Spiel starten' 
                            : 'Warte auf Spieler (min. 3)',
                        style: const TextStyle(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        backgroundColor: canStart ? Colors.green : null,
                        foregroundColor: canStart ? Colors.white : null,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerList() {
    return AnimatedBuilder(
      animation: _multiplayerService,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spieler (${_multiplayerService.lobbyPlayers.length}/30)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...(_multiplayerService.lobbyPlayers.map((player) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: player.isHost ? Colors.amber : Colors.deepPurple,
                  child: Icon(
                    player.isHost ? Icons.star : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(player.name),
                subtitle: Text(player.isHost ? 'Host' : (player.isReady ? 'Bereit' : 'Nicht bereit')),
                trailing: player.isHost
                    ? const Icon(Icons.star, color: Colors.amber)
                    : Icon(
                        player.isReady ? Icons.check_circle : Icons.schedule,
                        color: player.isReady ? Colors.green : Colors.grey,
                      ),
              );
            }).toList()),
          ],
        );
      },
    );
  }

  Widget _buildQRCode() {
    return Column(
      children: [
        const Text(
          'QR-Code zum Beitreten',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: QrImageView(
            data: widget.lobbyId,
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableText(
              widget.lobbyId,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.lobbyId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code kopiert!')),
                );
              },
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
      ],
    );
  }

  void _sendMessage() {
    if (_chatController.text.trim().isNotEmpty) {
      _multiplayerService.sendChatMessage(_chatController.text.trim());
      _chatController.clear();
    }
  }

  Widget _buildSettings() {
    final playerCount = _multiplayerService.lobbyPlayers.length;
    final maxImpeters = Math.max(1, (playerCount / 3).floor());
    
    // Ensure current impeter count is valid
    if (_impeterCount > maxImpeters) {
      _impeterCount = maxImpeters;
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Spiel-Einstellungen',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Impeter Anzahl - Kompakter
          Row(
            children: [
              const Text('Impeter: '),
              Expanded(
                child: Slider(
                  value: _impeterCount.toDouble(),
                  min: 1,
                  max: Math.max(1, maxImpeters).toDouble(),
                  divisions: Math.max(1, maxImpeters - 1),
                  label: '$_impeterCount',
                  onChanged: (value) {
                    setState(() {
                      _impeterCount = value.round();
                    });
                  },
                ),
              ),
              Text('$_impeterCount'),
            ],
          ),
          
          // Timer - Kompakter
          Row(
            children: [
              const Text('Zeit: '),
              Expanded(
                child: Slider(
                  value: _timerMinutes.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_timerMinutes min',
                  onChanged: (value) {
                    setState(() {
                      _timerMinutes = value.round();
                    });
                  },
                ),
              ),
              Text('${_timerMinutes}min'),
            ],
          ),
          
          // Tips anzeigen - Kompakter
          CheckboxListTile(
            title: const Text('Tipps für Impeter'),
            subtitle: const Text('Hinweise anzeigen'),
            value: _showTips,
            onChanged: (value) {
              setState(() {
                _showTips = value ?? true;
              });
            },
            dense: true,
          ),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Spieler: $playerCount | Max. Impeter: $maxImpeters',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    final gameSettings = {
      'playerCount': _multiplayerService.lobbyPlayers.length,
      'impeterCount': _impeterCount,
      'roundCount': 1,
      'timerMinutes': _timerMinutes,
      'gameMode': 'normal',
      'customWords': [],
      'showTips': _showTips,
    };
    
    print('Starting game with settings: $gameSettings');
    _multiplayerService.startGame(gameSettings);
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MultiplayerGameScreen extends StatefulWidget {
  final String lobbyId;
  final String playerName;

  const MultiplayerGameScreen({
    super.key,
    required this.lobbyId,
    required this.playerName,
  });

  @override
  _MultiplayerGameScreenState createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  late final MultiplayerService _multiplayerService;
  final _wordController = TextEditingController();
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  
  String _currentTurnPlayer = '';
  int _currentTurnIndex = 0;
  bool _isMyTurn = false;
  bool _chatVisible = false;
  
  // Game state
  String? _myWord;
  String? _myTip;
  bool _isImposter = false;
  List<String> _submittedWords = [];
  Map<String, dynamic>? _gameSettings;

  @override
  void initState() {
    super.initState();
    _multiplayerService = MultiplayerService();
    _setupGameListeners();
  }

  void _setupGameListeners() {
    _multiplayerService.onGameDataReceived = (gameData) {
      print('Raw game data received: $gameData');
      setState(() {
        _myWord = gameData['word'];
        _myTip = gameData['tip'];
        _isImposter = gameData['isImposter'] ?? false;
        _currentTurnIndex = gameData['currentTurn'] ?? 0;
        _currentTurnPlayer = gameData['currentPlayer'] ?? '';
        _isMyTurn = _currentTurnPlayer == widget.playerName;
        _gameSettings = gameData;
      });
      print('Game data processed: word=$_myWord, tip=$_myTip, isImposter=$_isImposter, currentPlayer=$_currentTurnPlayer, isMyTurn=$_isMyTurn');
    };
    
    _multiplayerService.onWordSubmitted = (playerName, word, nextPlayerName) {
      print('Word submitted: $playerName said "$word", next player: $nextPlayerName');
      setState(() {
        _submittedWords.add('$playerName: $word');
        _currentTurnPlayer = nextPlayerName;
        _isMyTurn = nextPlayerName == widget.playerName;
      });
      print('Updated turn state: currentPlayer=$_currentTurnPlayer, isMyTurn=$_isMyTurn');
    };

    _multiplayerService.onVoteResults = (results) {
      // Handle vote results
    };

    _multiplayerService.onChatMessage = (message) {
      setState(() {});
      if (_chatVisible) {
        _scrollToBottom();
      }
    };
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spiel: ${widget.lobbyId}'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Role/Word Display
              Card(
                margin: const EdgeInsets.all(16),
                color: _isImposter ? Colors.red.shade50 : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        _isImposter ? '🎭 Du bist IMPOSTER' : '✅ Du bist NORMALER SPIELER',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isImposter ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isImposter && _myTip != null) ...[
                        Text(
                          'Dein Hinweis:',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _myTip!,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ] else if (!_isImposter && _myWord != null) ...[
                        Text(
                          'Dein Wort:',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _myWord!,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Turn Status
              Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _isMyTurn 
                          ? '🎯 Du bist dran!' 
                          : _currentTurnPlayer.isNotEmpty 
                            ? '⏳ $_currentTurnPlayer ist dran'
                            : (_myWord != null || _myTip != null) 
                              ? '⏳ Spiel lädt...'
                              : '⏳ Warte auf Spieler...',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (_isMyTurn) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _wordController,
                          decoration: const InputDecoration(
                            labelText: 'Dein Wort eingeben',
                            border: OutlineInputBorder(),
                            hintText: 'Beschreibe das Wort...',
                          ),
                          onSubmitted: (_) => _submitWord(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitWord,
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Wort abgeben'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Submitted Words History
              Expanded(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '📝 Eingereichte Wörter',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _submittedWords.isEmpty
                          ? const Center(
                              child: Text(
                                'Noch keine Wörter eingereicht',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _submittedWords.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple,
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(_submittedWords[index]),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Collapsible Chat Overlay
          if (_chatVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 60,
              top: MediaQuery.of(context).size.height * 0.4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              '💬 Chat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => setState(() => _chatVisible = false),
                              icon: const Icon(Icons.close, color: Colors.white),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _multiplayerService,
                          builder: (context, child) {
                            return ListView.builder(
                              controller: _scrollController,
                              itemCount: _multiplayerService.chatMessages.length,
                              itemBuilder: (context, index) {
                                final message = _multiplayerService.chatMessages[index];
                                final isOwnMessage = message.playerName == widget.playerName;
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 3,
                              ),
                              child: Row(
                                mainAxisAlignment: isOwnMessage
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOwnMessage
                                          ? Colors.deepPurple
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isOwnMessage)
                                          Text(
                                            message.playerName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        Text(
                                          message.message,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isOwnMessage
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: const InputDecoration(
                              hintText: 'Chat-Nachricht...',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _sendChatMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sendChatMessage,
                          icon: const Icon(Icons.send),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Chat Toggle Button
          Positioned(
            left: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => setState(() => _chatVisible = !_chatVisible),
              backgroundColor: Colors.deepPurple,
              child: Icon(
                _chatVisible ? Icons.chat_bubble : Icons.chat_bubble_outline,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitWord() {
    if (_wordController.text.trim().isNotEmpty && _isMyTurn) {
      _multiplayerService.submitWord(_wordController.text.trim());
      _wordController.clear();
    }
  }

  void _sendChatMessage() {
    if (_chatController.text.trim().isNotEmpty) {
      _multiplayerService.sendChatMessage(_chatController.text.trim());
      _chatController.clear();
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _chatController.dispose();
    super.dispose();
  }
}