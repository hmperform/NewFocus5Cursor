# Focus5 - Mental Performance Training App

## Overview

Focus5 is a Flutter-based mobile and web application designed to help users improve their mental performance, focus, and mindfulness through various training exercises, courses, and tools. The app provides a comprehensive set of features including courses, audio sessions, journaling, chat functionality, and interactive games, all aimed at enhancing the user's mental capabilities.

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider pattern
- **Local Storage**: SharedPreferences for persisting user data
- **UI Components**: Custom Flutter widgets following Material Design principles
- **Navigation**: Flutter Navigator 2.0

## Project Structure

The project follows a standard Flutter architecture with the following key directories:

```
focus5/
├── lib/
│   ├── constants/        # App-wide constants including themes
│   ├── models/           # Data models
│   ├── providers/        # State management providers
│   ├── screens/          # UI screens organized by feature
│   │   ├── auth/         # Authentication screens
│   │   ├── home/         # Main tabs and related screens
│   │   ├── more/         # Additional features like games
│   │   ├── onboarding/   # User onboarding flow
│   │   └── article/      # Article-related screens
│   ├── services/         # API and business logic services
│   ├── utils/            # Utility functions and helpers
│   └── widgets/          # Reusable UI components
├── assets/               # Static assets (images, fonts, etc.)
└── test/                 # Unit and widget tests
```

## Key Features

### Home Dashboard
- Personalized daily content recommendations
- Day streak tracking
- Quick access to featured courses and sessions

### Explore Tab
- Browse courses by category
- Featured content and recommendations
- Search functionality

### Direct Messages
- Chat interface for communication with coaches or other users
- Reactions and interactive elements

### Profile Management
- User profile customization
- Progress tracking and achievements
- Subscription management

### Journal
- Daily journaling with date selection
- Journal entry search and filtering
- Mood and emotion tracking

### Mental Training Games
1. **Concentration Grid Game**
   - Find numbers in sequence from 0-99
   - Multiple difficulty levels
   - High score tracking

2. **Word Search Game**
   - Find hidden words in a letter grid
   - Includes mental performance vocabulary
   - Timer and best times tracking

### Additional Features
- Audio sessions for meditation and focus
- Articles and educational content
- Paywall for premium content
- Theme customization (light/dark mode)

## Recent Changes and Improvements

### UI/UX Enhancements
- Updated AppBar theme to use accent colors consistently
- Enhanced course detail screen with floating action button and improved layout
- Fixed various overflow issues in the dashboard
- Improved readability and contrast throughout the app

### Feature Additions
- Added date selection feature to journal entries
- Improved visibility of chat reactions
- Added Word Search game with the following capabilities:
  - 12x12 grid with words hidden in various directions
  - Tap-based selection (first letter then last letter)
  - Word definitions shown when found
  - Best times leaderboard
  - Responsive design with word bank below the grid

### Bug Fixes
- Fixed "course not found" error by ensuring proper content initialization
- Enhanced paywall functionality to prevent unauthorized access
- Fixed layout overflow issues in dashboard and course detail screens
- Resolved navigation issues between screens

### Performance Improvements
- Optimized image loading with FadeInImage for smoother transitions
- Improved scrolling performance in list views
- Enhanced state management to prevent unnecessary rebuilds

## Theming

The application supports both light and dark themes, controlled through the ThemeProvider. The primary color scheme includes:

- **Primary Color**: Main brand color used for key UI elements
- **Accent Color**: Secondary color for highlights and interactive elements
- **Background Color**: Scaffold and container backgrounds
- **Surface Color**: Card and elevated surface backgrounds
- **Text Colors**: Primary, secondary, and accent text colors

## Getting Started

To run the application:

```bash
# Navigate to the project directory
cd focus5

# Get dependencies
flutter pub get

# Run the app
flutter run -d <device>
```

Where `<device>` can be:
- `chrome` or `edge` for web
- Device ID for physical devices
- Emulator name for Android/iOS emulators

## Future Enhancements

Planned features and improvements include:
- Additional mental training games
- Enhanced analytics for tracking progress
- Social features for connecting with other users
- Integration with wearable devices for biometric data
- Expanded course library and content

## Documentation

For more detailed information about specific components:
- See the code documentation within individual files
- Refer to the API documentation for service integrations
- Check the design documents for UI/UX specifications

---

© 2023 Focus5 - Mental Performance Training
