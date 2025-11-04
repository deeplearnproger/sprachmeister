# B1 Schreiben Coach – Setup & Usage Guide

## 📝 Übersicht

Das B1 Schreiben Coach Modul erweitert AITalkingApp um **schriftliche Prüfungsvorbereitung** für das Goethe-Zertifikat B1 (Schreiben Teil 1 & 2). Alle Daten bleiben lokal auf Ihrem Gerät, und die Überprüfung erfolgt entweder durch ein lokales LLM (Mistral-7B) oder durch einen heuristischen Fallback.

### Hauptfunktionen

- **Teil 1: Forumsbeitrag** (ca. 150 Wörter, 50 Min)
- **Teil 2: E-Mail** (mind. 100 Wörter, 25 Min)
- **Automatische Bewertung** nach 4 Kriterien (Aufgabenerfüllung, Kohärenz, Wortschatz, Strukturen)
- **Detaillierte Fehleranalyse** (Rechtschreibung, Grammatik, Syntax, Zeichensetzung)
- **Echtzeit-Metriken**: Wortzahl, Satzlänge, TTR, Schreibtempo
- **Offline-Betrieb**: Keine Internetverbindung erforderlich
- **Export**: JSON-Export für Analysen

---

## 🚀 Ersteinrichtung

### Voraussetzungen

- **Xcode 15+** (für iOS 17+)
- **macOS Sonoma+** (für Entwicklung)
- **LLM-Modell** (optional): `Mistral-7B-Instruct-v0.3-Q4_K_M.gguf` (4,1 GB)

### Schritt 1: Projekt öffnen

```bash
cd "/Users/t.abkiliamov/Documents/deutsch app/AITalkingApp"
open AITalkingApp.xcodeproj
```

### Schritt 2: Dependencies hinzufügen

Das Projekt enthält alle notwendigen Swift-Dateien. Stellen Sie sicher, dass folgende Dateien in Xcode sichtbar sind:

**Models:**
- `WritingTask.swift`
- `WritingAttempt.swift`

**Services:**
- `LLMChecker.swift`
- `LocalGGUFChecker.swift`
- `HeuristicChecker.swift`
- `WritingMetricsAnalyzer.swift`
- `WritingTimer.swift`
- `ExportService.swift`
- `WritingStorageService.swift`

**Views:**
- `ModePickerView.swift`
- `WritingTaskPickerView.swift`
- `WritingEditorView.swift`
- `WritingResultView.swift`
- `WritingHistoryView.swift`

**Resources:**
- `Resources/Seeds/teil1_topics.json`
- `Resources/Seeds/teil2_email_scenarios.json`
- `Resources/rubric_prompt_de.txt`

**Falls Dateien fehlen:**
1. Rechtsklick auf Projektordner → "Add Files to 'AITalkingApp'"
2. Wählen Sie die fehlenden Dateien aus
3. ✅ "Copy items if needed"
4. ✅ Target: AITalkingApp

### Schritt 3: LLM-Modell einrichten (optional)

#### Option A: Modell bereits vorhanden

Das Modell befindet sich hier:
```
/Users/t.abkiliamov/Documents/deutsch app/LLMModels/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf
```

Konfiguration wird automatisch geladen. Keine weiteren Schritte erforderlich!

#### Option B: Anderes Modell verwenden

1. Modell herunterladen von [HuggingFace](https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.3-GGUF)
2. In `LLMModels/` Ordner verschieben
3. Pfad anpassen in `LLMCheckerConfig.default` (in `LLMChecker.swift`):

```swift
static let `default` = LLMCheckerConfig(
    modelPath: "/Pfad/zu/Ihrem/Modell.gguf",
    maxTokens: 2048,
    temperature: 0.3,
    promptTemplatePath: nil
)
```

#### Option C: Ohne LLM (nur Heuristik)

Funktioniert sofort! Der `HeuristicChecker` ist immer verfügbar und analysiert Texte offline basierend auf:
- Schlüsselwort-Matching für Unterpunkte
- Häufige Rechtschreibfehler
- Großschreibung von Nomen
- Kommasetzung vor Konjunktionen
- Konnektoren-Zählung
- TTR-Berechnung

---

## 📱 App-Nutzung

### 1. App starten

1. Gerät/Simulator auswählen
2. ⌘R (Build & Run)
3. Bei erstem Start: Mikrofonzugriff erlauben (für Sprechen-Modul)

### 2. Schreiben-Modus wählen

**Hauptbildschirm → "Schreiben"**

Sie sehen:
- **Teil 1: Forumsbeitrag** (15 Themen verfügbar)
- **Teil 2: E-Mail** (15 Szenarien verfügbar)
- **Statistiken**: Anzahl Versuche, Gesamtzeit, Durchschnittsbewertung

### 3. Aufgabe auswählen

**Beispiel: Teil 1 – "Hausaufgaben in der Schule"**

Aufgabe zeigt:
- ✏️ Thema
- 📋 Situation (Kontext)
- ✅ 4 Unterpunkte (müssen alle behandelt werden)
- ⏱️ Zeitlimit: 50 Min
- 📏 Ziel: 130–170 Wörter

### 4. Text schreiben

**Editor-Features:**
- **Timer startet automatisch** beim ersten Buchstaben
- **Wortzähler** (live): zeigt aktuellen Stand vs. Ziel
- **Pause-Funktion**: ⏸️ bei Unterbrechungen
- **Tipps-Button** 💡: zeigt Redemittel/Formeln
- **Aufgabenpunkte**: ℹ️ zum Nachlesen

**Farbcodes:**
- 🟢 Grün: Wortanzahl im Zielbereich
- 🟠 Orange: Zu wenig Wörter
- 🔴 Rot: Zu viele Wörter

### 5. Prüfen lassen

**"Prüfen"-Button** wird aktiv bei ≥70% der Mindestwortzahl.

**Was passiert:**
1. Timer stoppt
2. Metriken werden berechnet
3. LLM prüft Text (oder Heuristik als Fallback)
4. Ergebnis-Screen erscheint

### 6. Ergebnis analysieren

**Ergebnis-Screen zeigt:**

#### A) Gesamtbewertung
- 🎯 **Score**: 0–5.0 (Durchschnitt der 4 Kriterien)
- 📊 **Niveau**: A2, B1, B1+, B2
- 💬 **Zusammenfassung**: Kurzes Feedback (2-3 Sätze)

#### B) Metriken
- 📝 Wortanzahl
- 📄 Satzanzahl
- ⏱️ Dauer
- ⚡ Wörter/Min
- 📈 TTR (Type-Token Ratio = Wortvielfalt)
- 🎓 Geschätztes Niveau

#### C) Kriterien (0–5 je Achse)
1. **Aufgabenerfüllung**: Alle Punkte behandelt? Register korrekt?
2. **Kohärenz**: Struktur, Konnektoren, Logik
3. **Wortschatz**: Vielfalt, Angemessenheit
4. **Strukturen**: Grammatik, Rechtschreibung, Zeichensetzung

#### D) Fehler
Für jeden Fehler:
- 🏷️ Typ (Orthografie, Morphologie, Syntax, ...)
- ❌ Fehlerhafte Stelle (Zitat aus Ihrem Text)
- ✅ Korrekturvorschlag

#### E) Verbesserungsvorschläge
- 3-4 konkrete Tipps
- Optional: Beispielsätze vom LLM

### 7. Export & Verwaltung

**Aktionen:**
- 📤 **JSON exportieren**: Teilen via Files, AirDrop, Mail
- ⭐ **Als Favorit markieren**: Für schnellen Zugriff
- 📖 **Text erneut lesen**: Volltext-Ansicht
- 🗑️ **Löschen**: In Verlaufs-Ansicht

**Verlauf öffnen:**
Hauptscreen → ⏱️ (oben rechts)

**Filter:**
- Alle Versuche
- Nur Teil 1
- Nur Teil 2

**Export-Optionen:**
- Einzelner Versuch als JSON
- Alle Versuche als Sammlung
- Analytics-Report (Aggregierte Statistiken)

---

## 🔧 Erweiterte Konfiguration

### LLM-Checker anpassen

**Datei:** `AITalkingApp/Services/LLMChecker.swift`

```swift
struct LLMCheckerConfig: Codable {
    let modelPath: String          // Pfad zur .gguf-Datei
    let maxTokens: Int             // Max. Token für Antwort (2048 empfohlen)
    let temperature: Double        // 0.1–0.5 für faktische Bewertung
    let promptTemplatePath: String? // Optional: Eigener Prompt
}
```

**Eigenen Prompt verwenden:**
1. Kopieren Sie `Resources/rubric_prompt_de.txt`
2. Passen Sie Kriterien/Format an
3. Pfad in Config setzen:
   ```swift
   promptTemplatePath: "/Pfad/zu/custom_prompt.txt"
   ```

### Seed-Daten erweitern

**Teil 1 Themen hinzufügen:**

Datei: `Resources/Seeds/teil1_topics.json`

```json
{
  "id": "teil1-99",
  "type": "forumPost",
  "topic": "Ihr neues Thema",
  "situation": "Kontext/Fragestellung",
  "subpoints": [
    "Unterpunkt 1",
    "Unterpunkt 2",
    "Unterpunkt 3",
    "Unterpunkt 4"
  ],
  "timeLimitMinutes": 50
}
```

**Teil 2 E-Mails hinzufügen:**

Datei: `Resources/Seeds/teil2_email_scenarios.json`

```json
{
  "id": "teil2-99",
  "type": "email",
  "topic": "Ihr E-Mail-Szenario",
  "situation": "Beschreibung der Situation",
  "subpoints": [
    "Was Sie schreiben sollen (Punkt 1)",
    "Was Sie schreiben sollen (Punkt 2)",
    "Was Sie schreiben sollen (Punkt 3)",
    "Was Sie schreiben sollen (Punkt 4)"
  ],
  "hints": [
    "Anrede: ...",
    "Hauptteil: ...",
    "Abschluss: ..."
  ],
  "timeLimitMinutes": 25
}
```

**Nach Änderungen:**
1. Clean Build Folder (⌘⇧K)
2. Rebuild (⌘B)
3. Run (⌘R)

### Heuristic Checker anpassen

**Datei:** `AITalkingApp/Services/HeuristicChecker.swift`

Anpassbare Elemente:
- `commonMistakes`: Häufige Rechtschreibfehler erweitern
- `germanFillerWords`: Füllwörter-Liste (aus `MetricsAnalyzer.swift`)
- `connectors`: Liste der Konnektoren
- Scoring-Formeln in `calculateScores()`

---

## 🧪 Tests ausführen

### Alle Tests

```bash
# In Xcode
⌘U (Test)
```

### Einzelne Tests

1. Öffnen Sie `AITalkingAppTests/WritingMetricsTests.swift`
2. Klicken Sie auf ◇ neben Funktionsname
3. Oder: ⌘U für alle Tests im File

### Test-Coverage

**Getestete Module:**
- ✅ `WritingMetricsAnalyzer`: Wortzählung, TTR, Phrasen, Unterpunkte
- ✅ `ExportService`: JSON-Export, Analytics
- ⚠️ `WritingTimer`: Manuelle Tests empfohlen (UI-Abhängigkeit)
- ⚠️ `LLMChecker`: Benötigt Modell für Integrationstests

**Testbericht:**
Xcode → Report Navigator (⌘9) → Test-Logs

---

## 📊 Datenstruktur & Export

### JSON-Export Format

**Einzelner Versuch:**

```json
{
  "id": "UUID",
  "task": {
    "type": "forumPost",
    "topic": "...",
    "subpoints": [...]
  },
  "text": "Ihr geschriebener Text...",
  "startedAt": "2025-10-23T10:30:00Z",
  "duration": 1800,
  "metrics": {
    "wordCount": 152,
    "sentenceCount": 9,
    "typeTokenRatio": 0.67,
    "phrasesUsed": ["Meiner Meinung nach", "außerdem"],
    "estimatedLevel": "B1+"
  },
  "evaluation": {
    "scores": {
      "aufgabenerfuellung": 4.0,
      "kohaerenz": 3.5,
      "wortschatz": 4.0,
      "strukturen": 3.5
    },
    "errors": [...],
    "summary": "...",
    "improvements": [...]
  }
}
```

**Analytics-Report:**

```json
{
  "exportDate": "2025-10-23T12:00:00Z",
  "totalAttempts": 25,
  "teil1Attempts": 15,
  "teil2Attempts": 10,
  "averageScore": 3.7,
  "averageWordCount": 145.3,
  "mostCommonErrors": {
    "orthografie": 12,
    "syntax": 8
  },
  "phrasesUsageStats": {
    "Meiner Meinung nach": 18,
    "außerdem": 15
  },
  "attempts": [...]
}
```

### Speicherort

**Lokal (App):**
```
~/Library/Developer/CoreSimulator/Devices/[UUID]/data/Containers/Data/Application/[UUID]/Documents/AITalkingApp/writing_attempts.json
```

**Nach Export:**
```
/tmp/Schreiben_[Type]_[Date].json
```

---

## 🐛 Troubleshooting

### Problem: JSON-Dateien werden nicht geladen

**Symptom:** Keine Aufgaben verfügbar in Task Picker.

**Lösung:**
1. Prüfen: Sind `.json`-Dateien im Target enthalten?
   - Xcode → File Inspector (⌥⌘1)
   - "Target Membership" → ✅ AITalkingApp
2. Falls nicht: Rechtsklick → "Add to Target"
3. Clean Build (⌘⇧K) → Rebuild

### Problem: LLM-Modell nicht gefunden

**Symptom:** Fehler "LLM model file not found".

**Lösung:**
1. Pfad prüfen:
   ```swift
   print(LLMCheckerConfig.default.modelPath)
   ```
2. Datei existiert?
   ```bash
   ls -lh "/Users/t.abkiliamov/Documents/deutsch app/LLMModels/"
   ```
3. Falls Modell woanders: Config anpassen (siehe oben)
4. **Heuristik nutzen:** Funktioniert immer als Fallback!

### Problem: App stürzt beim Prüfen ab

**Lösung:**
1. Prüfen Sie Console-Logs (⌘⇧Y in Xcode)
2. Häufige Ursachen:
   - Zu kurzer Text: Mindestens 70% der Mindestwortanzahl
   - JSON-Parsing-Fehler: LLM-Antwort ungültig → Fallback auf Heuristik
3. Workaround: Heuristik-Modus erzwingen:
   ```swift
   // In WritingEditorView.swift, checkWriting()
   let checker: LLMChecker = HeuristicChecker() // Statt LocalGGUFChecker
   ```

### Problem: Timer läuft nicht

**Lösung:**
- Timer startet erst beim **ersten Buchstaben**
- Pause/Resume: Buttons nutzen
- Bei Absturz: Timer-State wird nicht persistiert (Design-Entscheidung)

### Problem: Export schlägt fehl

**Lösung:**
1. Speicherplatz prüfen
2. Berechtigungen: App hat Zugriff auf Documents
3. Simulator: Files-App öffnen → "On My iPhone" → AITalkingApp

---

## 📚 Architektur-Übersicht

```
┌─────────────────────────────────────────────┐
│            SwiftUI Views                    │
│  ┌─────────┐  ┌──────────┐  ┌────────────┐ │
│  │  Mode   │  │ Writing  │  │  Writing   │ │
│  │ Picker  │─▶│  Editor  │─▶│  Result    │ │
│  └─────────┘  └──────────┘  └────────────┘ │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│           Services Layer                    │
│  ┌──────────────┐  ┌──────────────────┐    │
│  │ Writing      │  │ LLMChecker       │    │
│  │ Storage      │  │ (Protocol)       │    │
│  │ Service      │  │  ├─ LocalGGUF    │    │
│  └──────────────┘  │  └─ Heuristic    │    │
│                    └──────────────────┘    │
│  ┌──────────────┐  ┌──────────────────┐    │
│  │ Writing      │  │ Export           │    │
│  │ Metrics      │  │ Service          │    │
│  │ Analyzer     │  └──────────────────┘    │
│  └──────────────┘                          │
│  ┌──────────────┐                          │
│  │ Writing      │                          │
│  │ Timer        │                          │
│  └──────────────┘                          │
└─────────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│            Data Layer                       │
│  ┌──────────────┐  ┌──────────────────┐    │
│  │ Writing      │  │ Writing          │    │
│  │ Task         │  │ Attempt          │    │
│  └──────────────┘  └──────────────────┘    │
│  ┌──────────────┐  ┌──────────────────┐    │
│  │ Writing      │  │ Writing          │    │
│  │ Metrics      │  │ Evaluation       │    │
│  └──────────────┘  └──────────────────┘    │
└─────────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│         Persistence / Resources             │
│  • writing_attempts.json                    │
│  • teil1_topics.json                        │
│  • teil2_email_scenarios.json               │
│  • rubric_prompt_de.txt                     │
│  • Mistral-7B (external)                    │
└─────────────────────────────────────────────┘
```

**Datenfluss beim Prüfen:**
1. User tippt → `WritingEditorView`
2. "Prüfen" → `WritingTimer.stop()` + `WritingMetricsAnalyzer`
3. `LocalGGUFChecker` (oder `HeuristicChecker`)
4. `WritingEvaluation` erstellt
5. `WritingAttempt` speichern via `WritingStorageService`
6. `WritingResultView` anzeigen

---

## 🚀 Nächste Schritte

### TODO für vollständige LLM-Integration

1. **llama.cpp einbinden:**
   - Swift Package: [llama.cpp-swift](https://github.com/ShenghaiWang/SwiftLLM) oder
   - C-Bridge: Siehe `LlamaRunner.h/.m` Stub
2. **LocalGGUFChecker erweitern:**
   - Ersetzen Sie `runInference()` Simulation durch echten llama.cpp-Call
3. **Modell-Import UI:**
   - `UIDocumentPicker` für .gguf-Upload
   - SHA256-Validierung
   - Settings-Screen für Modellpfad

### Empfohlene Erweiterungen

- 📸 **Screenshot beim Ergebnis**: Teilen-Feature
- 📈 **Fortschritts-Tracking**: Scores über Zeit visualisieren
- 🎯 **Personalisierte Tipps**: ML-basierte Schwachstellenerkennung
- 🌐 **iCloud Sync**: Cross-Device Verlauf
- 📖 **Beispiel-Texte**: Musterlösungen anzeigen

---

## 📞 Support & Feedback

**Bugs melden:**
- GitHub Issues: [Projektlink]
- In-App: Logs exportieren via Export-Feature

**Fragen:**
- Dokumentation: [ARCHITECTURE.md](ARCHITECTURE.md)
- Code-Kommentare: Alle Services haben ausführliche Inline-Docs

**Beitragen:**
1. Fork erstellen
2. Feature-Branch: `git checkout -b feature/name`
3. Tests hinzufügen
4. Pull Request mit Beschreibung

---

## 📄 Lizenz & Hinweise

- **Offline-First**: Keine Daten verlassen Ihr Gerät
- **Goethe-Institut**: Offizielle Bewertungskriterien als Referenz (nicht autorisiert)
- **Mistral-7B**: Apache 2.0 Lizenz
- **App**: Siehe [LICENSE](LICENSE)

**Disclaimer:** Dieses Tool dient der Übung. Es ersetzt keine offizielle Prüfungsvorbereitung oder professionelle Bewertung durch zertifizierte Prüfer.

---

**Version:** 1.0.0
**Letztes Update:** 23.10.2025
**Maintainer:** Tymur Abkiliamov
