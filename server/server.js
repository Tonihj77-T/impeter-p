const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

app.use(cors());
app.use(express.json());

// Store active lobbies
const lobbies = new Map();

// Load words from JSON file
let wordsData = {};
try {
  const wordsPath = path.join(__dirname, '..', 'assets', 'words.json');
  wordsData = JSON.parse(fs.readFileSync(wordsPath, 'utf8'));
} catch (error) {
  console.error('Could not load words.json:', error);
  // Fallback words
  wordsData = {
    "places": [
      {"word": "Italien", "tip": "Stiefel"},
      {"word": "Paris", "tip": "Licht"},
      {"word": "Sahara", "tip": "Sand"}
    ]
  };
}

// Lobby structure
class Lobby {
  constructor(id, hostSocketId, hostName) {
    this.id = id;
    this.hostSocketId = hostSocketId;
    this.players = [{
      socketId: hostSocketId,
      name: hostName,
      isHost: true,
      isReady: false
    }];
    this.gameState = 'waiting'; // waiting, playing, finished
    this.currentWord = '';
    this.currentTurn = 0;
    this.gameData = {};
    this.chatMessages = [];
    this.votes = new Map();
    this.createdAt = Date.now();
  }

  addPlayer(socketId, name) {
    if (this.players.length >= 30) return false;
    
    this.players.push({
      socketId,
      name,
      isHost: false,
      isReady: false
    });
    return true;
  }

  removePlayer(socketId) {
    const index = this.players.findIndex(p => p.socketId === socketId);
    if (index !== -1) {
      this.players.splice(index, 1);
      // If host left, make first player the new host
      if (this.players.length > 0 && socketId === this.hostSocketId) {
        this.hostSocketId = this.players[0].socketId;
        this.players[0].isHost = true;
      }
      return true;
    }
    return false;
  }

  getPlayer(socketId) {
    return this.players.find(p => p.socketId === socketId);
  }

  allPlayersReady() {
    return this.players.length >= 3 && this.players.every(p => p.isReady || p.isHost);
  }

  startGame(gameSettings) {
    console.log('Starting game with settings:', gameSettings);
    this.gameState = 'playing';
    this.gameData = gameSettings;
    this.currentTurn = 0;
    
    // Select random word
    const categories = Object.keys(wordsData);
    const randomCategory = categories[Math.floor(Math.random() * categories.length)];
    const words = wordsData[randomCategory];
    const selectedWord = words[Math.floor(Math.random() * words.length)];
    
    this.currentWord = selectedWord.word;
    this.wordTip = selectedWord.tip;
    console.log('Selected word:', this.currentWord, 'tip:', this.wordTip);
    
    // Determine imposters
    const requestedImposterCount = gameSettings.impeterCount || gameSettings.imposterCount || 1;
    const maxImposters = Math.max(1, Math.floor(this.players.length / 3));
    const imposterCount = Math.min(requestedImposterCount, maxImposters);
    console.log('Player count:', this.players.length, 'Requested imposters:', requestedImposterCount, 'Final imposter count:', imposterCount);
    
    // Ensure we have at least 1 imposter
    const actualImposterCount = Math.max(1, imposterCount);
    
    const imposterIndices = [];
    while (imposterIndices.length < actualImposterCount) {
      const randomIndex = Math.floor(Math.random() * this.players.length);
      if (!imposterIndices.includes(randomIndex)) {
        imposterIndices.push(randomIndex);
      }
    }
    console.log('Selected imposter indices:', imposterIndices);
    
    // Assign roles
    this.players.forEach((player, index) => {
      const isImposter = imposterIndices.includes(index);
      player.isImposter = isImposter;
      player.word = isImposter ? null : this.currentWord;
      player.tip = isImposter ? this.wordTip : null;
      console.log(`Player ${player.name} (index ${index}): isImposter=${isImposter}, word=${player.word}, tip=${player.tip}`);
    });
    
    return {
      word: this.currentWord,
      tip: this.wordTip,
      players: this.players.map(p => ({
        socketId: p.socketId,
        name: p.name,
        isImposter: p.isImposter,
        word: p.word,
        tip: p.tip
      })),
      currentTurn: this.currentTurn,
      currentPlayer: this.players[this.currentTurn].name
    };
  }

  submitWord(socketId, word) {
    const playerIndex = this.players.findIndex(p => p.socketId === socketId);
    if (playerIndex !== this.currentTurn) {
      return null; // Not player's turn
    }
    
    this.submittedWords = this.submittedWords || [];
    this.submittedWords.push({
      playerName: this.players[playerIndex].name,
      word: word,
      timestamp: Date.now()
    });
    
    // Move to next turn
    this.currentTurn = (this.currentTurn + 1) % this.players.length;
    
    return {
      playerName: this.players[playerIndex].name,
      word: word,
      nextTurn: this.currentTurn,
      nextPlayer: this.players[this.currentTurn].name,
      allWords: this.submittedWords
    };
  }
}

// Clean up old lobbies periodically
setInterval(() => {
  const now = Date.now();
  const LOBBY_TIMEOUT = 3 * 60 * 60 * 1000; // 3 hours
  
  for (const [lobbyId, lobby] of lobbies) {
    if (now - lobby.createdAt > LOBBY_TIMEOUT) {
      lobbies.delete(lobbyId);
      console.log(`Cleaned up old lobby: ${lobbyId}`);
    }
  }
}, 30 * 60 * 1000); // Check every 30 minutes

io.on('connection', (socket) => {
  console.log(`User connected: ${socket.id}`);

  // Create new lobby
  socket.on('create_lobby', (data) => {
    const lobbyId = generateLobbyCode();
    const lobby = new Lobby(lobbyId, socket.id, data.hostName);
    lobbies.set(lobbyId, lobby);
    
    socket.join(lobbyId);
    socket.emit('lobby_created', {
      lobbyId,
      lobby: {
        id: lobby.id,
        players: lobby.players,
        gameState: lobby.gameState
      }
    });
    
    console.log(`Lobby created: ${lobbyId} by ${data.hostName}`);
  });

  // Join existing lobby
  socket.on('join_lobby', (data) => {
    const lobby = lobbies.get(data.lobbyId);
    if (!lobby) {
      socket.emit('error', { message: 'Lobby not found' });
      return;
    }

    if (lobby.gameState !== 'waiting') {
      socket.emit('error', { message: 'Game already in progress' });
      return;
    }

    if (lobby.addPlayer(socket.id, data.playerName)) {
      socket.join(data.lobbyId);
      
      // Notify all players in lobby
      io.to(data.lobbyId).emit('player_joined', {
        player: lobby.getPlayer(socket.id),
        lobby: {
          id: lobby.id,
          players: lobby.players,
          gameState: lobby.gameState
        }
      });
      
      console.log(`${data.playerName} joined lobby: ${data.lobbyId}`);
    } else {
      socket.emit('error', { message: 'Lobby is full' });
    }
  });

  // Player ready/unready
  socket.on('player_ready', (data) => {
    const lobby = lobbies.get(data.lobbyId);
    if (lobby) {
      const player = lobby.getPlayer(socket.id);
      if (player) {
        player.isReady = data.ready;
        io.to(data.lobbyId).emit('player_ready_changed', {
          socketId: socket.id,
          ready: data.ready,
          allReady: lobby.allPlayersReady()
        });
      }
    }
  });

  // Start game
  socket.on('start_game', (data) => {
    const lobby = lobbies.get(data.lobbyId);
    if (lobby && lobby.hostSocketId === socket.id && lobby.allPlayersReady()) {
      const gameData = lobby.startGame(data.gameSettings);
      
      // Send individual game data to each player including the host
      lobby.players.forEach(player => {
        const playerGameData = {
          word: player.word,
          tip: player.tip,
          isImposter: player.isImposter,
          currentTurn: gameData.currentTurn,
          currentPlayer: gameData.currentPlayer,
          allPlayers: lobby.players.map(p => ({ name: p.name, socketId: p.socketId }))
        };
        
        if (player.socketId === socket.id) {
          // Send to host (current socket)
          socket.emit('game_started', playerGameData);
        } else {
          // Send to other players
          socket.to(player.socketId).emit('game_started', playerGameData);
        }
        
        console.log(`Sent game data to ${player.name}: isImposter=${player.isImposter}, word=${player.word}, tip=${player.tip}`);
      });
      
      console.log(`Game started in lobby: ${data.lobbyId}`);
    }
  });

  // Chat message
  socket.on('chat_message', (data) => {
    const lobby = lobbies.get(data.lobbyId);
    if (lobby) {
      const player = lobby.getPlayer(socket.id);
      if (player) {
        const message = {
          id: uuidv4(),
          playerName: player.name,
          message: data.message,
          timestamp: Date.now()
        };
        
        lobby.chatMessages.push(message);
        io.to(data.lobbyId).emit('chat_message', message);
      }
    }
  });

  // Word submission for turn-based gameplay
  socket.on('submit_word', (data) => {
    const lobby = lobbies.get(data.lobbyId);
    if (lobby && lobby.gameState === 'playing') {
      const result = lobby.submitWord(socket.id, data.word);
      if (result) {
        io.to(data.lobbyId).emit('word_submitted', {
          playerName: result.playerName,
          word: result.word,
          nextTurn: result.nextTurn,
          nextPlayerName: result.nextPlayer,
          allWords: result.allWords
        });
        console.log(`Word submitted by ${result.playerName}: "${result.word}", next player: ${result.nextPlayer}`);
      }
    }
  });

  // Vote submission
  socket.on('submit_vote', (data) => {
    const lobby = lobbies.get(data.lobbyId);
    if (lobby) {
      lobby.votes.set(socket.id, data.vote);
      
      // Check if all players have voted
      if (lobby.votes.size === lobby.players.length) {
        const voteResults = Array.from(lobby.votes.values());
        lobby.votes.clear();
        
        io.to(data.lobbyId).emit('vote_results', {
          results: voteResults
        });
      } else {
        io.to(data.lobbyId).emit('vote_received', {
          votesCount: lobby.votes.size,
          totalPlayers: lobby.players.length
        });
      }
    }
  });

  // Disconnect
  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.id}`);
    
    // Remove player from any lobby they were in
    for (const [lobbyId, lobby] of lobbies) {
      if (lobby.removePlayer(socket.id)) {
        if (lobby.players.length === 0) {
          // Delete empty lobby
          lobbies.delete(lobbyId);
          console.log(`Deleted empty lobby: ${lobbyId}`);
        } else {
          // Notify remaining players
          io.to(lobbyId).emit('player_left', {
            socketId: socket.id,
            lobby: {
              id: lobby.id,
              players: lobby.players,
              gameState: lobby.gameState
            }
          });
        }
        break;
      }
    }
  });
});

// Generate random lobby code
function generateLobbyCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < 6; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    lobbies: lobbies.size,
    timestamp: new Date().toISOString()
  });
});

// Get lobby info
app.get('/lobby/:id', (req, res) => {
  const lobby = lobbies.get(req.params.id);
  if (lobby) {
    res.json({
      id: lobby.id,
      players: lobby.players.map(p => ({ name: p.name, isHost: p.isHost, isReady: p.isReady })),
      gameState: lobby.gameState,
      playerCount: lobby.players.length
    });
  } else {
    res.status(404).json({ error: 'Lobby not found' });
  }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Impeter multiplayer server running on port ${PORT}`);
});