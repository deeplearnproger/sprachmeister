# B1 Schreiben Coach – Dateiliste

## Neu erstellte Dateien

### 📁 Models (2 Dateien)
```
AITalkingApp/Models/
├── WritingTask.swift              # Modell für Schreibaufgaben (Teil 1/2)
└── WritingAttempt.swift           # Modell für Versuche, Metriken, Bewertungen
```

### 📁 Services (7 Dateien)
```
AITalkingApp/Services/
├── LLMChecker.swift               # Protocol für Textprüfung
├── LocalGGUFChecker.swift         # LLM-Checker (Mistral-7B)
├── HeuristicChecker.swift         # Offline Fallback-Checker
├── WritingMetricsAnalyzer.swift   # TTR, Phrasen, Unterpunkte, Level
├── WritingTimer.swift             # Timer + PaceTracker
├── ExportService.swift            # JSON-Export
└── WritingStorageService.swift    # Persistierung
```

### 📁 Views (5 Dateien)
```
AITalkingApp/Views/
├── ModePickerView.swift           # Hauptmenü (Sprechen/Schreiben)
├── WritingTaskPickerView.swift    # Aufgabenauswahl
├── WritingEditorView.swift        # Haupteditor mit Timer
├── WritingResultView.swift        # Ergebnisanzeige
└── WritingHistoryView.swift       # Verlaufsansicht
```

### 📁 Resources (4 Dateien)
```
AITalkingApp/Resources/
├── rubric_prompt_de.txt           # LLM System-Prompt
└── Seeds/
    ├── teil1_topics.json          # 15 Forum-Themen
    └── teil2_email_scenarios.json # 15 E-Mail-Szenarien
```

### 📁 Tests (2 Dateien)
```
AITalkingAppTests/
├── WritingMetricsTests.swift      # Unit-Tests für Metriken
└── ExportServiceTests.swift       # Unit-Tests für Export
```

### 📁 Documentation (2 Dateien)
```
AITalkingApp/
├── SCHREIBEN_README.md            # Vollständige Anleitung
└── SCHREIBEN_FILES_CREATED.md     # Diese Datei
```

### 📁 Scripts (1 Datei)
```
AITalkingApp/scripts/
└── setup_schreiben.sh             # Setup-Verifikation
```

### ✏️ Geänderte Dateien (1 Datei)
```
AITalkingApp/
└── ContentView.swift              # Zeigt jetzt ModePickerView
```

---

## Dateistatistik

| Kategorie | Anzahl | Zeilen Code (ca.) |
|-----------|--------|-------------------|
| Models | 2 | ~400 |
| Services | 7 | ~1800 |
| Views | 5 | ~1600 |
| Resources | 4 | ~1000 (JSON/TXT) |
| Tests | 2 | ~300 |
| Docs | 2 | ~800 (Markdown) |
| Scripts | 1 | ~150 (Bash) |
| **GESAMT** | **23** | **~6050** |

---

## Keine Löschungen!

⚠️ **Wichtig:** Das Schreiben-Modul ist eine **Erweiterung**, keine Migration. Alle bestehenden Sprechen-Dateien bleiben erhalten:

**Behalten:**
- ✅ `ScenarioPicker.swift` (für Sprechen-Modul)
- ✅ `PracticeScreen.swift` (für Sprechen-Modul)
- ✅ `ConversationOrchestrator.swift` (für Sprechen-Modul)
- ✅ `LLMService.swift` (für Sprechen-Modul)
- ✅ Alle anderen Sprechen-bezogenen Dateien

**Navigation:**
```
ContentView
    └─ ModePickerView
         ├─ Sprechen → ScenarioPicker (existierend)
         └─ Schreiben → WritingTaskPickerView (NEU)
```

---

## Xcode Target Membership

**Alle neuen Dateien müssen zum Target hinzugefügt werden:**

1. Öffnen Sie `AITalkingApp.xcodeproj`
2. Für jede neue `.swift`-Datei:
   - Wählen Sie die Datei in Xcode
   - File Inspector (⌥⌘1)
   - "Target Membership" → ✅ AITalkingApp

3. Für Resources:
   - `Resources/` Ordner → ✅ AITalkingApp
   - ⚠️ NICHT für `.txt`/`.json` Build Phases → "Copy Bundle Resources"

**Automatisch prüfen:**
```bash
cd "/Users/t.abkiliamov/Documents/deutsch app/AITalkingApp"
chmod +x scripts/setup_schreiben.sh
./scripts/setup_schreiben.sh
```

---

## Dependency-Graph

```
ContentView
    └── ModePickerView
         ├── ScenarioPicker (Sprechen)
         └── WritingTaskPickerView (Schreiben)
              ├── WritingStorageService
              │    └── WritingTask (loads from Seeds)
              ├── WritingEditorView
              │    ├── WritingTimer
              │    ├── WritingPaceTracker
              │    └── LLMChecker (Protocol)
              │         ├── LocalGGUFChecker
              │         └── HeuristicChecker
              └── WritingResultView
                   ├── ExportService
                   └── WritingHistoryView
```

---

## Bundle Size Impact

**Vor Schreiben-Modul:** ~5 MB (App Binary + Assets)
**Nach Schreiben-Modul:** ~5.2 MB (App Binary + Assets + JSON Seeds)

**LLM-Modell (extern):** 4,1 GB (nicht im Bundle)

---

## Next Steps

1. ✅ Dateien erstellt
2. ⏳ Xcode öffnen
3. ⏳ Target Membership prüfen
4. ⏳ Clean Build (⌘⇧K)
5. ⏳ Build & Run (⌘R)
6. ⏳ LLM-Modell konfigurieren (optional)

**Vollständige Anleitung:** `SCHREIBEN_README.md`

---

**Erstellt:** 23.10.2025
**Version:** 1.0.0
**Maintainer:** Tymur Abkiliamov
