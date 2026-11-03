# Slice of Life (SOL)

A gamified task and habit app: complete real-life tasks to earn XP, level up your own persona,
and see which areas of your life you are growing in.

Built with Flutter. Persona 3 Reload inspired UI using the colors of the SOL pitch deck.

## Features
- Create, edit and complete tasks (name, description, category, XP reward)
- XP, levels and a level-up popup
- Recurring tasks (daily / specific weekdays) that reset automatically, plus streaks
- Category filter and Ongoing / Completed / All view
- Stats screen: pentagon chart of XP per category
- Persona (character) picker with a Stardew-style selector
- Local storage (shared_preferences)

## Project layout
```
lib/
  main.dart                 app entry + theme
  core/                     palette + pixel font, slanted shapes, popup transition
  models/                   Task model, XP -> level math
  widgets/                  slanted buttons and chips
  character/                persona silhouettes + picker
  popups/                   name prompt, level-up, option menu, stats
  screens/                  home screen, task editor
assets/
  fonts/                    Silkscreen-Regular.ttf, Silkscreen-Bold.ttf  (add your own copies)
  characters/               male_1..3, female_1..3, neutral_1..3 .png     (add your own copies)
```

## Run
```
flutter pub get
flutter run
```
Android builds: raise the number after `+` in `pubspec.yaml` (`version: 1.0.0+N`) for every build you install over an old one.
