# AITalkingApp - Project Structure

## Overview
Приложение для подготовки к экзамену Goethe-Zertifikat B1 с двумя модулями: **Sprechen** (говорение) и **Schreiben** (письмо).

---

## Folder Structure

```
AITalkingApp/
├── AITalkingAppApp.swift              # App entry point
├── ContentView.swift                  # Root view
│
├── Shared/                            # Общие компоненты
│   └── Views/
│       └── ModePickerView.swift       # Выбор режима (Sprechen/Schreiben)
│
├── Sprechen/                          # Модуль говорения (Speaking)
│   ├── Views/                         # 4 files
│   │   ├── ScenarioPicker.swift       # Выбор сценария разговора
│   │   ├── PracticeScreen.swift       # Экран практики (запись голоса)
│   │   ├── TranscriptScreen.swift     # Просмотр транскрипта диалога
│   │   └── AttemptsHistoryView.swift  # История попыток
│   │
│   ├── Models/                        # 5 files
│   │   ├── Scenario.swift             # Сценарии разговоров
│   │   ├── Attempt.swift              # Попытки пользователя
│   │   ├── Transcript.swift           # Транскрипты диалогов
│   │   ├── Metrics.swift              # Метрики (слова, филлеры)
│   │   └── ConversationState.swift    # Состояние диалога
│   │
│   ├── Services/                      # 5 files
│   │   ├── AudioService.swift         # Запись аудио
│   │   ├── STTService.swift           # Speech-to-Text (распознавание)
│   │   ├── TTSService.swift           # Text-to-Speech (синтез речи)
│   │   ├── ResponseEngine.swift       # Генерация ответов
│   │   └── StorageService.swift       # Хранение попыток
│   │
│   ├── Orchestration/                 # 1 file
│   │   └── ConversationOrchestrator.swift  # Управление диалогом
│   │
│   └── Utils/                         # 2 files
│       ├── MetricsAnalyzer.swift      # Анализ метрик
│       └── VAD.swift                  # Voice Activity Detection
│
└── Schreiben/                         # Модуль письма (Writing)
    ├── Views/                         # 4 files
    │   ├── WritingTaskPickerView.swift    # Выбор задания
    │   ├── WritingEditorView.swift        # Редактор текста
    │   ├── WritingResultView.swift        # Результаты проверки
    │   └── WritingHistoryView.swift       # История попыток
    │
    ├── Models/                        # 2 files
    │   ├── WritingTask.swift          # Задания (30 встроенных)
    │   └── WritingAttempt.swift       # Попытки с оценками
    │
    └── Services/                      # 7 files
        ├── LLMChecker.swift           # Протокол проверки текста
        ├── OpenRouterChecker.swift    # ✅ АКТИВНЫЙ - LLM через API
        ├── HeuristicChecker.swift     # Offline fallback проверка
        ├── WritingMetricsAnalyzer.swift   # Анализ текста
        ├── WritingStorageService.swift    # Хранение попыток
        ├── WritingTimer.swift         # Таймер для заданий
        └── ExportService.swift        # Экспорт в JSON
```

---

## Module Breakdown

### **Sprechen (Speaking) - 17 files**
Модуль для практики устной речи:
- Запись голоса через микрофон
- Распознавание речи (STT)
- Синтез речи (TTS)
- Диалог с виртуальным экзаменатором
- Анализ метрик (слова, филлеры, беглость)

### **Schreiben (Writing) - 14 files**
Модуль для практики письма:
- 30 заданий (Teil 1: блог, Teil 2: email)
- Редактор с таймером и счетчиком слов
- LLM-проверка через OpenRouter API (Mistral/Gemini/Qwen)
- Детальная оценка по критериям Goethe B1
- Оффлайн fallback (HeuristicChecker)

### **Shared - 1 file**
Общие компоненты:
- ModePickerView - выбор между Sprechen и Schreiben

---

## Key Technologies

### Sprechen Module
- **AudioKit** - запись/воспроизведение аудио
- **Speech Framework** - STT (Speech-to-Text)
- **AVFoundation** - синтез речи (TTS)
- **Voice Activity Detection** - определение речи
- **SwiftUI** - интерфейс

### Schreiben Module
- **OpenRouter API** - LLM анализ текста
  - Поддержка: Mistral 7B, Google Gemini, Qwen, Llama
- **Heuristic Analysis** - оффлайн проверка
- **JSON Export** - экспорт результатов
- **SwiftUI** - интерфейс

---

## Data Flow

### Sprechen Flow
```
User speaks → AudioService records
           → STTService transcribes
           → ConversationOrchestrator processes
           → ResponseEngine generates response
           → TTSService speaks response
           → StorageService saves attempt
           → MetricsAnalyzer calculates metrics
```

### Schreiben Flow
```
User writes text → WritingEditor
                → WritingTimer tracks time
                → WritingMetricsAnalyzer calculates metrics
                → OpenRouterChecker sends to LLM API
                   ↓ (if fails)
                   → HeuristicChecker (offline)
                → WritingResultView shows evaluation
                → WritingStorageService saves attempt
                → ExportService exports to JSON (optional)
```

---

## Configuration

### API Keys
⚠️ **ВАЖНО**: Не храните API ключи в коде!

Создайте файл `Config.swift` в `Schreiben/Services/`:
```swift
enum Config {
    static let openRouterAPIKey = "YOUR_API_KEY_HERE"
}
```

И используйте в `WritingEditorView.swift`:
```swift
let checker = OpenRouterChecker(apiKey: Config.openRouterAPIKey)
```

### Supported Models (OpenRouter)
- `mistralai/mistral-7b-instruct:free` (primary)
- `google/gemini-2.0-flash-exp:free`
- `qwen/qwen-2-7b-instruct:free`
- `meta-llama/llama-3.2-3b-instruct:free`
- Автоматическое переключение при rate limit

---

## File Count & LOC

| Module | Files | Estimated LOC |
|--------|-------|---------------|
| Sprechen | 17 | ~3,000 |
| Schreiben | 14 | ~3,250 |
| Shared | 1 | ~145 |
| Root | 2 | ~30 |
| **TOTAL** | **34** | **~6,425** |

---

## Recent Changes (Oct 2025)

### ✅ Completed
- Реорганизация в модульную структуру (Sprechen/Schreiben/Shared)
- Удалён LocalGGUFChecker.swift (не интегрирован)
- Удалён rubric_prompt_de.txt (не используется)
- Удалён LLMCheckerConfig (не нужен для API)
- Интеграция OpenRouter API с 8 бесплатными моделями
- Добавлена автоматическая ротация моделей при ошибках
- Исправлены NaN ошибки в графиках результатов

### ⚠️ TODO
- [ ] Вынести API ключ в Config.swift
- [ ] Добавить тесты для Sprechen модуля
- [ ] Обновить Xcode project.pbxproj с новыми путями
- [ ] Добавить .gitignore для Config.swift

---

## Development Guide

### Adding New Sprechen Scenario
1. Edit `Sprechen/Models/Scenario.swift`
2. Add to `allScenarios` array
3. Test in `ScenarioPicker.swift`

### Adding New Schreiben Task
1. Edit `Schreiben/Models/WritingTask.swift`
2. Add to `allTasks` array
3. Test in `WritingTaskPickerView.swift`

### Testing LLM Checkers
```swift
// In WritingEditorView.swift
let checker = OpenRouterChecker(apiKey: "...")
let evaluation = try await checker.checkWriting(
    task: task,
    text: userText,
    metrics: metrics
)
```

---

## Architecture

### Design Patterns
- **MVVM** (Model-View-ViewModel)
- **Protocol-Oriented** (LLMChecker protocol)
- **Dependency Injection** (Services passed to views)
- **State Machine** (ConversationState)
- **Repository Pattern** (StorageService)

### Best Practices
- ✅ Separated concerns (Sprechen vs Schreiben)
- ✅ Protocol-based abstractions
- ✅ Offline fallback mechanisms
- ✅ Comprehensive error handling
- ⚠️ API keys need better security

---

## License
Proprietary - Goethe B1 Exam Preparation App
