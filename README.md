# 🎭 Impeter - Das Bluff-Spiel

Ein spannendes Gesellschaftsspiel für 3-30 Spieler, bei dem ein oder mehrere Impeter versuchen, unentdeckt zu bleiben!

## 📱 Verfügbare Versionen

- **Android APK**: Native Android-App mit vollem Funktionsumfang
- **Web Version**: Spiele direkt im Browser mit Flutter Web
- **Cross-Platform**: Identische Features auf allen Plattformen

## 🎮 Wie funktioniert das Spiel?

### Spielprinzip
1. **Setup**: Wähle 3-30 Spieler und bestimme die Anzahl der Impeter
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
- **3-30 Spieler** unterstützt
- **Mehrere Impeter** möglich (automatisch berechnet: max. 1/3 der Spieler)
- **200+ Wörter** mit passenden Tipps
- **Wort-Verlauf**: Verhindert Wiederholungen
- **Dark Mode** für angenehmes Spielen
- **Mehrsprachig**: Deutsch und Englisch

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
flutter build apk --release

# Web Version bauen
flutter build web --release

# Entwicklungs-Server starten
flutter run -d chrome  # Für Web
flutter run             # Für Android (Gerät angeschlossen)
```

## 📂 Projektstruktur

```
Impeter/
├── lib/
│   └── main.dart          # Haupt-App Code (Flutter/Dart)
├── web/
│   ├── index.html         # Web Template
│   └── words.json         # Wort-Datenbank
├── build/
│   ├── web/               # Gebaute Web-Version
│   └── app/outputs/       # Gebaute Android APK
├── android/               # Android-spezifische Dateien
├── assets/
│   └── words.json         # Wort-Datenbank für mobile App
└── README.md
```

## 🎲 Beispiel-Spielrunde

**Situation**: 6 Spieler, 1 Impeter, Wort: "Mikrowelle"

1. **Setup**: Anna, Ben, Clara, David, Eva, Frank
2. **Rollen**:
   - Anna, Ben, Clara, David, Eva: Sehen "Mikrowelle"
   - Frank (Impeter): Sieht nur Tipp "Strahlung"
3. **Diskussion**:
   - Anna: "Ich benutze das täglich in der Küche"
   - Frank: "Ja, ist sehr praktisch für... äh... Energie?"
   - Ben: "Definitiv! Besonders für warme Sachen"
   - Frank: "Genau, mit dieser speziellen... Technik"
4. **Verdacht**: Frank wirkt unsicher → wird eliminiert
5. **Ergebnis**: Normale Spieler gewinnen!

## 🛠️ Technische Details

### Built with
- **Flutter 3.32.0** - Cross-platform Framework
- **Dart 3.8.0** - Programmiersprache
- **Material Design 3** - UI Components
- **Canvas Rendering** - Für Web-Performance

### Kompatibilität
- **Android**: API Level 21+ (Android 5.0+)
- **Web**: Moderne Browser (Chrome, Firefox, Safari, Edge)
- **Desktop**: Theoretisch möglich (nicht getestet)

### Performance
- **APK Größe**: ~21.7MB
- **Web Bundle**: Optimiert mit Tree-Shaking
- **Startup**: Sofort spielbereit
- **Memory**: Effiziente Speichernutzung

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
- Achtet darauf, dass niemand das Display anderer sieht
- Ermutigt lebhafte Diskussionen
- Zeitlimits können Spannung erhöhen

## 🐛 Bekannte Funktionen

### Was funktioniert perfekt:
- ✅ Alle Kernfunktionen
- ✅ Mehrere Impeter
- ✅ Wort-Verlauf ohne Wiederholungen
- ✅ Fortsetzung nach Elimination
- ✅ Dark Mode
- ✅ Mobile und Web-Version identisch
- ✅ Timer für Diskussionsrunden

### Geplante Verbesserungen:
- 🔄 Mehr Wort-Kategorien
- 🔄 Spielstatistiken
- 🔄 Custom Word Pakete

## 📄 Lizenz

Dieses Projekt ist für persönliche und nicht-kommerzielle Nutzung entwickelt.

## 🤝 Beitragen

Das Spiel ist vollständig funktional! Bei Verbesserungsvorschlägen oder neuen Wort-Ideen, gerne Issues oder Pull Requests erstellen.

---

**Viel Spaß beim Bluffen! 🎭**
