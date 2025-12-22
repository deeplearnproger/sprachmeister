# SprachMeister

An iOS app for practicing German language skills through AI-powered conversations and writing exercises.

## Features

### Sprechen (Speaking)
- Practice speaking with AI-powered conversations
- Real-time speech recognition (German STT)
- Natural text-to-speech responses
- Detailed metrics: WPM, filler words, grammar analysis
- Multiple exam scenarios (Goethe B1 style)

### Schreiben (Writing)
- Writing practice with AI feedback
- Grammar and style correction
- Vocabulary analysis
- Progress tracking and history

### General
- Fully offline speech processing (on-device)
- Local data storage
- Modern SwiftUI interface
- Dark/Light mode support

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/SprachMeister.git
cd SprachMeister
```

2. Configure API Key (for AI features)
```bash
cp SprachMeisterApp/Schreiben/Services/Config.swift.example SprachMeisterApp/Schreiben/Services/Config.swift
```
Then edit `Config.swift` and add your OpenRouter API key.

3. Open in Xcode
```bash
open SprachMeister.xcodeproj
```

4. Configure signing
   - Open project settings
   - Select your Team in Signing & Capabilities
   - Xcode will create a provisioning profile automatically

5. Run on device
   - Connect your iPhone (iOS 16+)
   - Select your device in Xcode
   - Press Cmd+R to build and run
   - On iPhone: Settings → General → VPN & Device Management → Trust the certificate

## First Launch

1. Allow microphone access when prompted
2. Allow speech recognition when prompted
3. For best TTS quality, download German voice: Settings → Accessibility → Spoken Content → Voices → German

## Architecture

```
SprachMeisterApp/
├── DesignSystem/          # Reusable UI components and tokens
│   ├── Components/        # DSButton, DSCard, DSChip, etc.
│   └── Tokens/            # Theme (colors, typography, spacing)
├── Sprechen/              # Speaking practice module
│   ├── Models/            # Data models
│   ├── Views/             # UI screens
│   ├── Services/          # Audio, STT, TTS services
│   ├── Orchestration/     # Conversation state machine
│   └── Utils/             # VAD, Metrics analyzer
├── Schreiben/             # Writing practice module
│   ├── Models/            # Writing task, attempt models
│   ├── Views/             # Editor, results, history views
│   └── Services/          # Checkers, storage, export
└── Shared/                # Shared components
```

## Technologies

- **SwiftUI** - Modern declarative UI
- **AVFoundation** - Audio recording and playback
- **Speech** - On-device speech recognition
- **Accelerate** - VAD (Voice Activity Detection)
- **async/await** - Modern concurrency

## Privacy

- Voice recordings are processed locally on device
- Writing exercises use secure AI services for analysis
- Progress data is stored locally
- No personal data is shared with third parties

See our [Privacy Policy](docs/index.html) for more details.

## Support

For questions or feedback, please open an issue on GitHub or contact support@sprachmeister.app

## License

This project is proprietary software. See [LICENSE](LICENSE) for details.

You may view the source code for reference purposes only. Copying, modification, or redistribution is not permitted without written permission.

---

Made with love for German learners
