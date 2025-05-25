# 🎭 Impeter - Das Online Bluff-Spiel

Ein spannendes Gesellschaftsspiel für 3-30 Spieler, bei dem ein oder mehrere Impeter versuchen, unentdeckt zu bleiben! Jetzt mit **Online-Multiplayer** und **Lobby-System**!

## 📱 Verfügbare Versionen

- **Android APK**: Native Android-App mit vollem Funktionsumfang (22.7MB)
- **Web Version**: Spiele direkt im Browser mit Flutter Web
- **Cross-Platform**: Identische Features auf allen Plattformen
- **Online-Multiplayer**: Erstelle oder trete Lobbys bei und spiele mit Freunden remote

## 🎮 Wie funktioniert das Spiel?

### Spielmodi
- **Lokal**: Alle Spieler nutzen ein Gerät (klassischer Modus)
- **Online-Multiplayer**: Jeder Spieler nutzt sein eigenes Gerät, verbunden über Lobbys

### Spielprinzip
1. **Setup**: 
   - **Lokal**: Wähle 3-30 Spieler und bestimme die Anzahl der Impeter
   - **Online**: Erstelle eine Lobby oder trete einer bei mit dem Lobby-Code
2. **Rollenvergabe**: Jeder Spieler erhält geheim seine Rolle
   - **Normale Spieler**: Bekommen ein Wort gezeigt (z.B. "Küchengerät")
   - **Impeter**: Bekommen nur einen Tipp zum Wort (z.B. "Hitze")
3. **Diskussion**: Alle reden über das Thema, ohne das Wort direkt zu nennen
4. **Abstimmung**: Gemeinsam wird entschieden, wer verdächtig ist
5. **Elimination**: Der gewählte Spieler scheidet aus
6. **Weiterspielen**: Das Spiel geht weiter, bis eine Fraktion gewinnt

### Gewinnbedingungen
- **Normale Spieler gewinnen**: Alle Impeter wurden eliminiert
- **Impeter gewinnen**: Sie sind gleichviele oder mehr als die normalen Spieler

## ✨ Features

### 🎯 Kernfunktionen
- **3-30 Spieler** unterstützt (lokal und online)
- **Online-Multiplayer** mit Lobby-System
- **Mehrere Impeter** möglich (automatisch berechnet: max. 1/3 der Spieler)
- **200+ Wörter** mit passenden Tipps
- **Wort-Verlauf**: Verhindert Wiederholungen
- **Dark Mode** für angenehmes Spielen
- **Mehrsprachig**: Deutsch und Englisch

### 🌐 Online-Multiplayer Features
- **Lobby-Erstellung**: Erstelle private Lobbys mit eindeutigen Codes
- **QR-Code Sharing**: Teile Lobby-Codes einfach per QR-Code
- **Real-time Chat**: Kommuniziere mit anderen Spielern in der Lobby
- **Ready-System**: Alle Spieler müssen bereit sein, bevor das Spiel startet
- **Automatische Synchronisation**: Alle Spieler sehen den gleichen Spielstand
- **Verbindungsanzeige**: Sieh den Online-Status aller Spieler

### 🎨 Animationen & UI
- **Card Flip Animationen** bei der Rollenenthüllung
- **Material Design** mit modernen UI-Komponenten
- **Responsive Design** für alle Bildschirmgrößen
- **Intuitive Navigation** zwischen Spielphasen

### ⚙️ Einstellungen
- **Tips System**: Impeter bekommen subtile Hinweise
- **Anpassbare Spielerzahl**: Von intimen 3er-Runden bis zu großen Gruppen
- **Impeter-Anzahl**: Automatisch optimiert oder manuell einstellbar
- **Sprache**: Deutsch oder Englisch

### 🔄 Intelligente Spiellogik
- **Fortsetzung nach Elimination**: Spiel geht weiter solange möglich
- **Eliminierte Spieler** werden automatisch aus zukünftigen Abstimmungen entfernt
- **Automatische Gewinn-Erkennung**: Spiel endet bei unmöglichen Situationen
- **Wort-Management**: Keine Wiederholungen bis alle Wörter verwendet wurden

## 🚀 Installation & Start

### Android
1. Lade die APK-Datei herunter
2. Installiere sie auf deinem Android-Gerät
3. Starte die App und leg sofort los!

### Web (Browser)
1. Öffne die `index.html` aus dem `build/web` Ordner
2. Oder starte einen lokalen Server:
   ```bash
   cd build/web
   python3 -m http.server 8080
   ```
3. Besuche `http://localhost:8080`

### Entwicklung
```bash
# Repository klonen
git clone https://github.com/Tonihj77-T/Impeter.git
cd Impeter

# Flutter Dependencies installieren
flutter pub get

# Android Version bauen
export JAVA_HOME=/path/to/java17
flutter build apk --release

# Web Version bauen
flutter build web --release

# Entwicklungs-Server starten
flutter run -d chrome  # Für Web
flutter run             # Für Android (Gerät angeschlossen)
```

#### Build-Anforderungen
- **Java 17** für Android builds (bei AGP 8.4.0+)
- **Flutter 3.32.0+** für beste Kompatibilität
- **Android SDK 35** für aktuellste Features

### Multiplayer-Server (Lobby-System)

Der Node.js-Server stellt das Lobby-System für Mehrspielerpartien bereit. Er ermöglicht das Erstellen und Betreten von Lobbys, Ready-State, Chat, Spielstart, Wort- und Abstimmungsrunden.

#### Voraussetzungen

- Node.js 16+ und npm
- (Optional) nodemon für automatische Neustarts in der Entwicklung

#### Installation und Start

```bash
cd server
npm install
# Production
npm start
# Development mit automatischem Neustart
npm run dev
```

Der Server lauscht standardmäßig auf Port 3000. Über die Umgebungsvariable `PORT` kann der Port angepasst werden.

#### HTTP-Endpunkte

| Methode | Pfad        | Beschreibung                                   |
| ------- | ----------- | ---------------------------------------------- |
| GET     | /health     | Healthcheck, zeigt Status und Anzahl Lobbys an |
| GET     | /lobby/:id  | Informationen zu einer Lobby abrufen           |

#### Socket.IO-Ereignisse

- `create_lobby` – Lobby erstellen (data: { hostName })
- `lobby_created` – Rückmeldung zur Lobby-Erstellung (data: { lobbyId, lobby })
- `join_lobby` – Lobby beitreten (data: { lobbyId, playerName })
- `player_joined` – Benachrichtigung über neuen Spieler
- `player_ready` – Ready-/Unready-Status setzen (data: { lobbyId, ready })
- `player_ready_changed` – Ready-Status geändert (data: { socketId, ready, allReady })
- `start_game` – Spiel starten (data: { lobbyId, gameSettings })
- `game_started` – Spiel hat begonnen
- `chat_message` – Chatnachricht senden (data: { lobbyId, message })
- `word_submitted` – Wort für aktuellen Zug übermitteln (data: { lobbyId, word })
- `submit_vote` – Stimme abgeben (data: { lobbyId, vote })
- `vote_received` – Zwischenfeedback zur Abstimmung (data: { votesCount, totalPlayers })
- `vote_results` – Abstimmungsergebnis (data: { results })
- `player_left` – Spieler hat Lobby verlassen

## 📂 Projektstruktur

```
Impeter/
├── lib/
│   ├── main.dart                  # Haupt-App Code (Flutter/Dart)
│   ├── multiplayer_screens.dart   # Online-Multiplayer UI
│   └── multiplayer_service.dart   # Socket.IO Service für Online-Features
├── web/
│   ├── index.html                 # Web Template
│   └── words.json                 # Wort-Datenbank
├── build/
│   ├── web/                       # Gebaute Web-Version
│   └── app/outputs/               # Gebaute Android APK (22.7MB)
├── android/                       # Android-spezifische Dateien
├── server/                        # Node.js Multiplayer-Server (Lobby-System)
│   ├── server.js                  # Socket.IO Server
│   └── package.json               # Node.js Dependencies
├── assets/
│   └── words.json                 # Wort-Datenbank für mobile App
└── README.md
```

## 🎲 Beispiel-Spielrunden

### Online-Multiplayer Runde
**Situation**: 6 Spieler in Online-Lobby "GAME42", 1 Impeter, Wort: "Mikrowelle"

1. **Lobby-Setup**: 
   - Anna erstellt Lobby → erhält Code "GAME42"
   - Ben, Clara, David, Eva, Frank treten bei
   - Alle markieren sich als "bereit"
2. **Rollen** (jeder auf seinem eigenen Gerät):
   - Anna, Ben, Clara, David, Eva: Sehen "Mikrowelle"
   - Frank (Impeter): Sieht nur Tipp "Strahlung"
3. **Diskussion** (über Chat oder Voice):
   - Anna: "Ich benutze das täglich in der Küche"
   - Frank: "Ja, ist sehr praktisch für... äh... Energie?"
   - Ben: "Definitiv! Besonders für warme Sachen"
   - Frank: "Genau, mit dieser speziellen... Technik"
4. **Abstimmung**: Jeder stimmt auf seinem Gerät ab
5. **Verdacht**: Frank wirkt unsicher → wird eliminiert
6. **Ergebnis**: Normale Spieler gewinnen!

### Lokale Runde
**Situation**: 4 Spieler um ein Gerät, 1 Impeter, Wort: "Fahrrad"

1. **Setup**: Gerät wird herumgereicht für Rolleneinsicht
2. **Diskussion**: Alle reden face-to-face
3. **Abstimmung**: Gemeinsame Entscheidung
4. **Spaß**: Direktes Interaction und Reaktionen!

## 🛠️ Technische Details

### Built with
- **Flutter 3.32.0** - Cross-platform Framework
- **Dart 3.8.0** - Programmiersprache
- **Material Design 3** - UI Components
- **Socket.IO Client 2.0.3** - Real-time Multiplayer Communication
- **Node.js Server** - Backend für Online-Lobbys
- **Canvas Rendering** - Für Web-Performance

### Kompatibilität
- **Android**: API Level 21+ (Android 5.0+)
- **Web**: Moderne Browser (Chrome, Firefox, Safari, Edge)
- **Desktop**: Theoretisch möglich (nicht getestet)

### Performance
- **APK Größe**: 22.7MB (Release Build)
- **Web Bundle**: Optimiert mit Tree-Shaking
- **Startup**: Sofort spielbereit
- **Memory**: Effiziente Speichernutzung
- **Online-Latenz**: <100ms bei stabiler Internetverbindung
- **Multiplayer**: Unterstützt bis zu 30 gleichzeitige Spieler pro Lobby

## 🎯 Spieltipps

### Für normale Spieler:
- Redet über das Wort, ohne es direkt zu nennen
- Achtet auf vage oder ausweichende Antworten
- Stellt gezielte Fragen zum Thema

### Für Impeter:
- Nutzt die Tipps clever
- Hört gut zu und adaptiert euch
- Bleibt ruhig und selbstbewusst
- Lenkt Verdacht auf andere

### Für Spielleiter:
- Erklärt die Regeln klar vor dem ersten Spiel
- **Lokal**: Achtet darauf, dass niemand das Display anderer sieht
- **Online**: Nutzt Voice-Chat für die beste Erfahrung
- Ermutigt lebhafte Diskussionen
- Zeitlimits können Spannung erhöhen

### Online-Multiplayer Tipps:
- Nutzt externe Voice-Chat (Discord, Zoom) für beste Kommunikation
- Der Lobby-Host kann das Spiel starten, sobald alle bereit sind
- QR-Codes machen das Lobby-Beitreten super einfach
- Chat-Funktion ist perfekt für stille Hinweise oder Verdächtigungen

## 🐛 Bekannte Funktionen

### Was funktioniert perfekt:
- ✅ Alle Kernfunktionen (lokal und online)
- ✅ Online-Multiplayer mit Lobbys
- ✅ Real-time Chat-System
- ✅ Mehrere Impeter
- ✅ Wort-Verlauf ohne Wiederholungen
- ✅ Fortsetzung nach Elimination
- ✅ Dark Mode
- ✅ Mobile und Web-Version identisch
- ✅ Timer für Diskussionsrunden
- ✅ QR-Code Lobby-Sharing
- ✅ Ready-System für Online-Spiele

### Bekannte Einschränkungen:
- ⚠️ QR-Scanner temporär deaktiviert (manuelle Code-Eingabe funktioniert)
- ⚠️ Online-Server läuft auf externem Server (kann gelegentlich offline sein)

### Geplante Verbesserungen:
- 🔄 QR-Scanner reaktivieren
- 🔄 Mehr Wort-Kategorien
- 🔄 Spielstatistiken
- 🔄 Custom Word Pakete
- 🔄 Voice-Chat Integration
- 🔄 Emoji-Reaktionen im Chat

## 📄 Lizenz

Dieses Projekt ist für persönliche und nicht-kommerzielle Nutzung entwickelt.

## 🤝 Beitragen

Das Spiel ist vollständig funktional mit lokalem und Online-Multiplayer! Bei Verbesserungsvorschlägen, neuen Wort-Ideen oder Fehlermeldungen, gerne Issues oder Pull Requests erstellen.

### Entwicklung beitreten:
- **Frontend**: Flutter/Dart Kenntnisse für UI-Verbesserungen
- **Backend**: Node.js/Socket.IO für Server-Features
- **Content**: Neue Wörter und Kategorien vorschlagen
- **Testing**: Multiplayer-Features testen und Feedback geben

---

**Viel Spaß beim Bluffen - lokal oder online! 🎭🌐**
