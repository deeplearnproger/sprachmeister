# 🎨 AITalkingApp - Premium UI Design System

## Обзор

Полная система дизайна для создания премиального, нативного iOS-интерфейса. Все токены, компоненты и паттерны в одном месте.

## 📁 Структура

```
AITalkingApp/
├── DesignSystem/
│   ├── Tokens/
│   │   ├── Theme.swift          ✅ СОЗДАН - главный файл токенов
│   │   ├── ColorAssets.xcassets  ⚠️ НУЖНО СОЗДАТЬ
│   │   └── Animations.swift      📝 TODO
│   └── Components/
│       ├── DSCard.swift          ✅ СОЗДАН
│       ├── DSButton.swift        📝 TODO - PrimaryButton, SecondaryButton
│       ├── DSChip.swift          📝 TODO - статус-чипы
│       ├── DSProgressBar.swift   📝 TODO - прогресс-бары
│       ├── DSScoreDial.swift     📝 TODO - круговой score 0-5
│       ├── DSInfoTile.swift      📝 TODO - метрики (иконка + число)
│       ├── DSEmptyState.swift    📝 TODO - пустые состояния
│       └── DSToast.swift         📝 TODO - уведомления
```

## 🎯 Быстрый старт

### 1. Настроить Color Assets

Создайте цвета в `Assets.xcassets` с поддержкой Dark Mode:

#### Primary Colors
- `Primary` - #3B82F6 (Light) / #60A5FA (Dark)
- `PrimaryLight` - #DBEAFE (Light) / #1E40AF (Dark)
- `PrimaryDark` - #1E40AF (Light) / #1E3A8A (Dark)

#### Secondary
- `Secondary` - #22C55E (Light) / #4ADE80 (Dark)
- `SecondaryLight` - #D1FAE5 (Light) / #166534 (Dark)

#### Semantic
- `Success` - #10B981 / #34D399
- `Warning` - #F59E0B / #FCD34D
- `Danger` - #EF4444 / #F87171
- `Info` - #3B82F6 / #60A5FA

#### Neutrals
- `Background` - #F8FAFC (Light) / #0B0B0F (Dark)
- `Surface` - #FFFFFF (Light) / #111827 (Dark)
- `SurfaceElevated` - #FFFFFF (Light) / #1F2937 (Dark)
- `Border` - #E5E7EB (Light) / #374151 (Dark)
- `Divider` - #F3F4F6 (Light) / #1F2937 (Dark)

#### Text
- `TextPrimary` - #111827 (Light) / #F9FAFB (Dark)
- `TextSecondary` - #6B7280 (Light) / #D1D5DB (Dark)
- `TextTertiary` - #9CA3AF (Light) / #9CA3AF (Dark)
- `TextDisabled` - #D1D5DB (Light) / #4B5563 (Dark)

### 2. Использовать в коде

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        DSCard(elevation: .medium) {
            VStack(alignment: .leading, spacing: Theme.spacing.md) {
                Text("Premium Card")
                    .font(Theme.typography.titleLarge)
                    .foregroundStyle(Theme.colors.textPrimary)

                Text("With design system tokens")
                    .font(Theme.typography.bodyMedium)
                    .foregroundStyle(Theme.colors.textSecondary)
            }
        }
        .padding()
        .background(Theme.colors.background)
    }
}
```

### 3. Добавить хаптики

```swift
Button("Tap Me") {
    Theme.haptics.selection()
    // your action
}
```

## 🧩 Компоненты (нужно создать)

### DSButton.swift

```swift
struct DSPrimaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            Theme.haptics.impactLight()
            action()
        }) {
            Text(title)
                .font(Theme.typography.labelLarge)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(ColorPalette.fallbackPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radii.lg))
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(Theme.motion.springy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
```

### DSScoreDial.swift (для WritingResultView)

```swift
struct DSScoreDial: View {
    let score: Double // 0-5
    let title: String
    @State private var animatedScore: Double = 0

    var normalizedScore: Double {
        max(0, min(1, score / 5.0))
    }

    var color: Color {
        switch score {
        case 4.5...: return ColorPalette.fallbackSuccess
        case 3.5..<4.5: return ColorPalette.fallbackPrimary
        case 2.5..<3.5: return ColorPalette.fallbackWarning
        default: return ColorPalette.fallbackDanger
        }
    }

    var body: some View {
        VStack(spacing: Theme.spacing.md) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Theme.colors.divider, lineWidth: 12)
                    .frame(width: 140, height: 140)

                // Progress circle
                Circle()
                    .trim(from: 0, to: animatedScore)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // Score text
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", score))
                        .font(Theme.typography.displayMedium)
                        .fontWeight(.bold)
                        .foregroundStyle(color)

                    Text("/ 5.0")
                        .font(Theme.typography.caption)
                        .foregroundStyle(Theme.colors.textTertiary)
                }
            }

            Text(title)
                .font(Theme.typography.titleMedium)
                .foregroundStyle(Theme.colors.textSecondary)
        }
        .onAppear {
            withAnimation(Theme.motion.gentle.delay(0.2)) {
                animatedScore = normalizedScore
            }
        }
    }
}
```

### DSChip.swift

```swift
struct DSChip: View {
    let icon: String
    let text: String
    let style: ChipStyle

    enum ChipStyle {
        case neutral, success, warning, info

        var backgroundColor: Color {
            switch self {
            case .neutral: return Color.gray.opacity(0.1)
            case .success: return ColorPalette.fallbackSuccess.opacity(0.1)
            case .warning: return ColorPalette.fallbackWarning.opacity(0.1)
            case .info: return ColorPalette.fallbackPrimary.opacity(0.1)
            }
        }

        var foregroundColor: Color {
            switch self {
            case .neutral: return Color.gray
            case .success: return ColorPalette.fallbackSuccess
            case .warning: return ColorPalette.fallbackWarning
            case .info: return ColorPalette.fallbackPrimary
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(Theme.typography.labelSmall)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(style.backgroundColor)
        .foregroundStyle(style.foregroundColor)
        .clipShape(Capsule())
    }
}
```

## 📱 Применение к экранам

### ModePickerView (Home)

**До:**
```swift
// Простые кнопки/карточки
```

**После:**
```swift
struct ModePickerView: View {
    var body: some View {
        VStack(spacing: Theme.spacing.xxl) {
            // Hero Section
            VStack(spacing: Theme.spacing.sm) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(ColorPalette.fallbackPrimary)

                Text("Goethe B1 Coach")
                    .font(Theme.typography.displaySmall)
                    .fontWeight(.bold)

                Text("Ihr persönlicher Tutor für die Prüfungsvorbereitung")
                    .font(Theme.typography.bodyMedium)
                    .foregroundStyle(Theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Theme.spacing.xxxl)

            // Mode Cards
            VStack(spacing: Theme.spacing.md) {
                ModeTappableCard(
                    title: "Sprechen üben",
                    subtitle: "Dialoge führen, Feedback erhalten",
                    icon: "mic.fill",
                    color: ColorPalette.fallbackPrimary
                ) {
                    // Navigate to Sprechen
                }

                ModeTappableCard(
                    title: "Schreiben üben",
                    subtitle: "Texte verfassen und bewerten lassen",
                    icon: "pencil.and.list.clipboard",
                    color: ColorPalette.fallbackSecondary
                ) {
                    // Navigate to Schreiben
                }
            }
            .padding(.horizontal)

            Spacer()

            // Privacy note
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                Text("Alle Daten bleiben auf Ihrem Gerät")
                    .font(Theme.typography.caption)
            }
            .foregroundStyle(Theme.colors.textTertiary)
            .padding(.bottom)
        }
        .background(Theme.colors.background)
    }
}

struct ModeTappableCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            Theme.haptics.selection()
            action()
        }) {
            HStack(spacing: Theme.spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color)
                    .frame(width: 56, height: 56)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radii.md))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.typography.titleLarge)
                        .foregroundStyle(Theme.colors.textPrimary)

                    Text(subtitle)
                        .font(Theme.typography.bodySmall)
                        .foregroundStyle(Theme.colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.colors.textTertiary)
            }
            .padding(Theme.spacing.lg)
            .background(Theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radii.xl))
            .shadow(
                color: Color.black.opacity(isPressed ? 0.05 : 0.08),
                radius: isPressed ? 4 : 8,
                y: isPressed ? 2 : 4
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.motion.springy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
```

### WritingTaskPickerView (Schreiben Üben)

Добавить:
1. **Dashboard-карточку** со статистикой вверху
2. **Поиск** через `.searchable()`
3. **SegmentedControl** для Teil 1/Teil 2
4. **Улучшенные карточки** тем с чипами

### WritingResultView (Ergebnis)

Заменить:
1. Круг оценки → `DSScoreDial(score: evaluation.scores.overall, title: "Gesamtbewertung")`
2. Прогресс-бары → Компонент `DSProgressBar`
3. Метрики → `DSInfoTile`
4. Секции "Was gut war" → `DSCard` с зелёной подсветкой

## 🔧 Чеклист интеграции

- [ ] Создать Color Assets в Xcode (Primary, Secondary, Success, Warning, Danger, Background, Surface, TextPrimary, TextSecondary)
- [ ] Создать компоненты DSButton.swift, DSChip.swift, DSProgressBar.swift, DSScoreDial.swift, DSInfoTile.swift
- [ ] Обновить ModePickerView с hero-секцией и tappable cards
- [ ] Обновить WritingTaskPickerView с dashboard, search, segmented control
- [ ] Обновить WritingResultView с DSScoreDial, новыми карточками
- [ ] Обновить WritingHistoryView с фильтрами и улучшенными строками
- [ ] Добавить Toast-систему для уведомлений
- [ ] Тестировать с Large Text (Accessibility)
- [ ] Тестировать в Dark Mode
- [ ] Добавить Reduce Motion support

## 📚 Референсы

- Apple HIG: https://developer.apple.com/design/human-interface-guidelines/
- SF Symbols: https://developer.apple.com/sf-symbols/
- Dynamic Type: https://developer.apple.com/design/human-interface-guidelines/typography

---

**Статус:** ⚠️ В процессе - созданы базовые токены и карточки, нужно создать остальные компоненты и применить к экранам.
