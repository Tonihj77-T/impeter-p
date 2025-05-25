const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

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
      lobby.gameState = 'playing';
      lobby.currentTurn = 0;
      lobby.gameData = data.gameSettings;
      
      io.to(data.lobbyId).emit('game_started', {
        gameData: lobby.gameData,
        players: lobby.players
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
      const currentPlayerIndex = lobby.currentTurn % lobby.players.length;
      const currentPlayer = lobby.players[currentPlayerIndex];
      
      if (currentPlayer.socketId === socket.id) {
        // Valid turn, broadcast the word
        lobby.currentTurn++;
        
        io.to(data.lobbyId).emit('word_submitted', {
          playerName: currentPlayer.name,
          word: data.word,
          nextTurn: lobby.currentTurn % lobby.players.length,
          nextPlayerName: lobby.players[lobby.currentTurn % lobby.players.length].name
        });
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