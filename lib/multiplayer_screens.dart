import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:math';
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
  final _multiplayerService = MultiplayerService();

  @override
  void initState() {
    super.initState();
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
                          icon: const Icon(Icons.add),
                          label: const Text('Lobby erstellen'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                              icon: const Icon(Icons.login),
                              label: const Text('Beitreten'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _scanQRCode(),
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('QR scannen'),
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
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-Code scannen'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text('Richte die Kamera auf den QR-Code'),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        widget.onCodeScanned(scanData.code!);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
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
  final _multiplayerService = MultiplayerService();
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isReady = false;
  bool _showQR = false;

  @override
  void initState() {
    super.initState();
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
              child: _showQR ? _buildQRCode() : _buildPlayerList(),
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
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: isOwnMessage
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOwnMessage
                                          ? Colors.deepPurple
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isOwnMessage)
                                          Text(
                                            message.playerName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        Text(
                                          message.message,
                                          style: TextStyle(
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
                              hintText: 'Nachricht eingeben...',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sendMessage,
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
          
          // Ready button
          if (!widget.isHost)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isReady = !_isReady;
                    });
                    _multiplayerService.setPlayerReady(_isReady);
                  },
                  icon: Icon(_isReady ? Icons.check : Icons.schedule),
                  label: Text(_isReady ? 'Bereit!' : 'Bereit machen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isReady ? Colors.green : null,
                    foregroundColor: _isReady ? Colors.white : null,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          
          // Start game button (host only)
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.all(16),
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
                      icon: const Icon(Icons.play_arrow),
                      label: Text(canStart 
                          ? 'Spiel starten' 
                          : 'Warte auf Spieler (min. 3)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _startGame() {
    final gameSettings = {
      'playerCount': _multiplayerService.lobbyPlayers.length,
      'impeterCount': GameSettings.instance.impeterCount,
      'roundCount': GameSettings.instance.roundCount,
      'timerMinutes': GameSettings.instance.timerMinutes,
      'gameMode': GameSettings.instance.gameMode.toString(),
      'customWords': GameSettings.instance.customWords,
      'showTips': GameSettings.instance.showTips,
    };
    
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
  final _multiplayerService = MultiplayerService();
  final _wordController = TextEditingController();
  final _chatController = TextEditingController();
  String _currentTurnPlayer = '';
  bool _isMyTurn = false;

  @override
  void initState() {
    super.initState();
    _setupGameListeners();
  }

  void _setupGameListeners() {
    _multiplayerService.onWordSubmitted = (playerName, word, nextPlayerName) {
      setState(() {
        _currentTurnPlayer = nextPlayerName;
        _isMyTurn = nextPlayerName == widget.playerName;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$playerName hat "$word" eingegeben')),
      );
    };

    _multiplayerService.onVoteResults = (results) {
      // Handle vote results
    };

    _multiplayerService.onChatMessage = (message) {
      setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spiel: ${widget.lobbyId}'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Game status
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _isMyTurn ? 'Du bist dran!' : '$_currentTurnPlayer ist dran',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_isMyTurn) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _wordController,
                      decoration: const InputDecoration(
                        labelText: 'Dein Wort eingeben',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _submitWord(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitWord,
                        child: const Text('Wort abgeben'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Chat
          Expanded(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Chat',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _multiplayerService,
                      builder: (context, child) {
                        return ListView.builder(
                          itemCount: _multiplayerService.chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = _multiplayerService.chatMessages[index];
                            final isOwnMessage = message.playerName == widget.playerName;
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: isOwnMessage
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOwnMessage
                                          ? Colors.deepPurple
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isOwnMessage)
                                          Text(
                                            message.playerName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        Text(
                                          message.message,
                                          style: TextStyle(
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