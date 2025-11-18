# OpenStreetMap Flutter App

A Flutter mobile application that uses OpenStreetMap with interactive features for navigation and location tracking.

## Screenshots

<img width="298" height="659" alt="image" src="https://github.com/user-attachments/assets/93c5cd5b-8161-4823-af05-05bb1ad3a5a7" />
<img width="298" height="659" alt="image" src="https://github.com/user-attachments/assets/9cc542cb-4750-410a-a3e9-d55760c8345f" />
<br>
<img width="298" height="659" alt="image" src="https://github.com/user-attachments/assets/08a19f7e-e26c-42ad-a4b5-79b39b844065" />
<img width="298" height="659" alt="image" src="https://github.com/user-attachments/assets/430c5053-fff0-4f25-b417-b658dbe6069a" />

## Features

- Interactive OpenStreetMap integration
- Real-time user location tracking
- Multiple map styles (Streets, Topographic, Dark, Satellite)
- Custom map markers with different types and clustering
- Route tracking and recording
- Route statistics (distance, duration, average speed)
- Saved routes history with favorites
- Modern Material Design UI
- Dark and light mode toggle
- Distance and time calculator between locations
- PDF reports for dashboard and routes
- AI-powered route assistant using Gemini API
- Default location set to Pitampura, Delhi with sample routes

## Getting Started

### Prerequisites

- Flutter SDK (version 3.19.6 or newer)
- Dart SDK (version 3.3.4 or newer)
- Android Studio / VS Code with Flutter extensions
- Android SDK (for Android development)
- Xcode (for iOS development)
- Gemini API key (for the chat assistant feature)

### Installation

1. Clone this repository:
```bash
git clone https://github.com/KrishGaur1354/osm-routing-app.git
```

2. Navigate to the project folder:
```bash
cd osm-routing-app
```

3. Install dependencies:
```bash
flutter pub get
```

4. Add your Gemini API key:
   - Open `lib/screens/chat_screen.dart`
   - Replace `ADD_YOUR_GEMINI_API_KEY_HERE` with your actual API key

5. Run the app:
```bash
flutter run
```

### Building an APK

#### Option 1: Using GitHub Actions (Recommended)

If you don't have the Android SDK installed locally, you can use GitHub Actions to build the APK:

1. Fork this repository on GitHub
2. Make your changes and push them to your fork
3. The GitHub Actions workflow will automatically build the APK
4. Go to the "Actions" tab in your GitHub repository
5. Click on the latest workflow run
6. Download the APK from the "Artifacts" section

#### Option 2: Building Locally

To build a release APK locally:

1. Make sure you have Android SDK installed and configured
2. Set the ANDROID_HOME environment variable:
   - Windows: `set ANDROID_HOME=C:\Users\YourUsername\AppData\Local\Android\Sdk`
   - Linux/macOS: `export ANDROID_HOME=$HOME/Android/Sdk`
3. Build the APK:
```bash
flutter build apk --release
```
4. The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## Usage

### Map Screen
- Explore the map with gestures (pan, zoom)
- Toggle location tracking
- Change map style
- Add and manage custom markers

### Route Tracker
- Calculate distance and time between locations
- Start tracking a new route
- View real-time statistics
- Save completed routes

### Dashboard
- View activity summary with statistics
- See weekly and monthly activity charts
- Download PDF reports of your activities

### Profile
- Toggle between dark and light mode
- Update personal information
- Configure app settings

### Route Assistant
- Chat with the AI assistant about your routes
- Get navigation advice
- Ask questions about tracked activities

## Dependencies

- flutter_map: For OpenStreetMap integration
- latlong2: For geographical coordinates
- geolocator: For device location
- permission_handler: For managing permissions
- flutter_map_marker_cluster: For clustering markers
- shared_preferences: For local storage
- intl: For date formatting
- uuid: For generating unique IDs
- pdf: For generating PDF reports
- path_provider: For file system access
- open_file: For opening PDF files
- flutter_chat_ui: For chat interface
- flutter_chat_types: For chat message types
- google_generative_ai: For Gemini API integration
- provider: For state management
- google_fonts: For custom typography

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenStreetMap contributors for the map data
- Flutter and Dart teams for the amazing framework
- Google for the Gemini API
