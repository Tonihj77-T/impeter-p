import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

class MultiplayerService extends ChangeNotifier {
  static final MultiplayerService _instance = MultiplayerService._internal();
  factory MultiplayerService() => _instance;
  MultiplayerService._internal();

  static const String SERVER_URL = 'http://194.164.207.131:3000';
  
  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentLobbyId;
  Timer? _connectionTimer;
  
  // Connection state
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get currentLobbyId => _currentLobbyId;
  
  // Lobby state
  List<MultiplayerPlayer> _lobbyPlayers = [];
  String _gameState = 'waiting';
  List<ChatMessage> _chatMessages = [];
  
  List<MultiplayerPlayer> get lobbyPlayers => _lobbyPlayers;
  String get gameState => _gameState;
  List<ChatMessage> get chatMessages => _chatMessages;

  // Event callbacks
  Function(String lobbyId)? onLobbyCreated;
  Function(MultiplayerPlayer player)? onPlayerJoined;
  Function(String socketId)? onPlayerLeft;
  Function(String socketId, bool ready)? onPlayerReadyChanged;
  Function()? onGameStarted;
  Function(Map<String, dynamic> gameData)? onGameDataReceived;
  Function(ChatMessage message)? onChatMessage;
  Function(String playerName, String word, String nextPlayerName)? onWordSubmitted;
  Function(Map<String, dynamic> results)? onVoteResults;
  Function(String message)? onError;

  void initialize() {
    _startAutoConnection();
  }

  void _startAutoConnection() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAndConnect();
    });
    _checkAndConnect(); // Initial connection attempt
  }

  Future<void> _checkAndConnect() async {
    if (_isConnected || _isConnecting) return;
    
    await _connectToServer();
  }

  Future<void> _connectToServer() async {
    if (_isConnecting) return;
    
    _isConnecting = true;
    notifyListeners();

    try {
      // Test server availability first
      final response = await http.get(
        Uri.parse('$SERVER_URL/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _socket = IO.io(SERVER_URL, 
          IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setTimeout(5000)
            .build()
        );

        _setupSocketListeners();
        _socket!.connect();
      }
    } catch (e) {
      print('Failed to connect to server: $e');
      _isConnecting = false;
      notifyListeners();
    }
  }

  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      print('Connected to multiplayer server');
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      print('Disconnected from multiplayer server');
      _isConnected = false;
      _isConnecting = false;
      _currentLobbyId = null;
      _lobbyPlayers.clear();
      _chatMessages.clear();
      notifyListeners();
    });

    _socket!.onConnectError((error) {
      print('Connection error: $error');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
    });

    // Lobby events
    _socket!.on('lobby_created', (data) {
      print('Lobby created: ${data['lobbyId']}');
      _currentLobbyId = data['lobbyId'];
      _updateLobbyState(data['lobby']);
      onLobbyCreated?.call(data['lobbyId']);
    });

    _socket!.on('player_joined', (data) {
      print('Player joined: ${data['player']['name']}');
      _updateLobbyState(data['lobby']);
      onPlayerJoined?.call(MultiplayerPlayer.fromJson(data['player']));
    });

    _socket!.on('player_left', (data) {
      print('Player left: ${data['socketId']}');
      _updateLobbyState(data['lobby']);
      onPlayerLeft?.call(data['socketId']);
    });

    _socket!.on('player_ready_changed', (data) {
      print('Player ready changed: ${data['socketId']} -> ${data['ready']}');
      // Find player and update ready status
      bool found = false;
      for (var player in _lobbyPlayers) {
        if (player.socketId == data['socketId']) {
          player.isReady = data['ready'];
          found = true;
          break;
        }
      }
      print('Player found and updated: $found');
      notifyListeners();
      onPlayerReadyChanged?.call(data['socketId'], data['ready']);
    });

    _socket!.on('game_started', (data) {
      print('Game started with full data: $data');
      _gameState = 'playing';
      notifyListeners();
      
      // Store game data for the current player first
      if (onGameDataReceived != null) {
        print('Calling onGameDataReceived with: $data');
        onGameDataReceived!(data);
      }
      
      // Then call game started to potentially navigate
      onGameStarted?.call();
    });

    _socket!.on('chat_message', (data) {
      print('Chat message received: ${data['message']}');
      final message = ChatMessage.fromJson(data);
      _chatMessages.add(message);
      notifyListeners();
      onChatMessage?.call(message);
    });

    _socket!.on('word_submitted', (data) {
      print('Word submitted event: $data');
      onWordSubmitted?.call(
        data['playerName'], 
        data['word'], 
        data['nextPlayer'] ?? data['nextPlayerName'] ?? ''
      );
    });

    _socket!.on('vote_results', (data) {
      onVoteResults?.call(data['results']);
    });

    _socket!.on('error', (data) {
      onError?.call(data['message']);
    });
  }

  void _updateLobbyState(Map<String, dynamic> lobbyData) {
    print('Updating lobby state: ${lobbyData['players'].length} players');
    _lobbyPlayers = (lobbyData['players'] as List)
        .map((p) => MultiplayerPlayer.fromJson(p))
        .toList();
    _gameState = lobbyData['gameState'];
    print('Players in lobby: ${_lobbyPlayers.map((p) => '${p.name}(${p.isReady ? "ready" : "not ready"})').join(", ")}');
    notifyListeners();
  }

  // Lobby operations
  Future<void> createLobby(String hostName) async {
    if (!_isConnected) {
      await _connectToServer();
      if (!_isConnected) {
        onError?.call('Keine Verbindung zum Server');
        return;
      }
    }

    _socket!.emit('create_lobby', {'hostName': hostName});
  }

  Future<void> joinLobby(String lobbyId, String playerName) async {
    if (!_isConnected) {
      await _connectToServer();
      if (!_isConnected) {
        onError?.call('Keine Verbindung zum Server');
        return;
      }
    }

    _currentLobbyId = lobbyId;
    _socket!.emit('join_lobby', {
      'lobbyId': lobbyId,
      'playerName': playerName
    });
  }

  void setPlayerReady(bool ready) {
    print('Setting player ready: $ready, connected: $_isConnected, lobbyId: $_currentLobbyId');
    if (_isConnected && _currentLobbyId != null) {
      _socket!.emit('player_ready', {
        'lobbyId': _currentLobbyId,
        'ready': ready
      });
      print('Emitted player_ready event');
    } else {
      print('Cannot set ready - not connected or no lobby');
    }
  }

  void startGame(Map<String, dynamic> gameSettings) {
    if (_isConnected && _currentLobbyId != null) {
      _socket!.emit('start_game', {
        'lobbyId': _currentLobbyId,
        'gameSettings': gameSettings
      });
    }
  }

  void sendChatMessage(String message) {
    print('Sending chat message: $message, connected: $_isConnected, lobbyId: $_currentLobbyId');
    if (_isConnected && _currentLobbyId != null) {
      _socket!.emit('chat_message', {
        'lobbyId': _currentLobbyId,
        'message': message
      });
      print('Emitted chat_message event');
    } else {
      print('Cannot send message - not connected or no lobby');
    }
  }

  void submitWord(String word) {
    if (_isConnected && _currentLobbyId != null) {
      _socket!.emit('submit_word', {
        'lobbyId': _currentLobbyId,
        'word': word
      });
    }
  }

  void submitVote(String vote) {
    if (_isConnected && _currentLobbyId != null) {
      _socket!.emit('submit_vote', {
        'lobbyId': _currentLobbyId,
        'vote': vote
      });
    }
  }

  void leaveLobby() {
    _currentLobbyId = null;
    _lobbyPlayers.clear();
    _chatMessages.clear();
    _gameState = 'waiting';
    notifyListeners();
    
    if (_isConnected) {
      _socket!.disconnect();
      _socket!.connect(); // Reconnect for future use
    }
  }

  void dispose() {
    _connectionTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}

class MultiplayerPlayer {
  String socketId;
  String name;
  bool isHost;
  bool isReady;

  MultiplayerPlayer({
    required this.socketId,
    required this.name,
    required this.isHost,
    required this.isReady,
  });

  factory MultiplayerPlayer.fromJson(Map<String, dynamic> json) {
    return MultiplayerPlayer(
      socketId: json['socketId'] ?? '',
      name: json['name'] ?? '',
      isHost: json['isHost'] ?? false,
      isReady: json['isReady'] ?? false,
    );
  }

  factory MultiplayerPlayer.empty() {
    return MultiplayerPlayer(
      socketId: '',
      name: '',
      isHost: false,
      isReady: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'socketId': socketId,
      'name': name,
      'isHost': isHost,
      'isReady': isReady,
    };
  }
}

class ChatMessage {
  String id;
  String playerName;
  String message;
  DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.playerName,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      playerName: json['playerName'],
      message: json['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}