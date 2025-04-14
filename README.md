# OpenStreetMap Flutter App

A Flutter mobile application that uses OpenStreetMap with interactive features for navigation and location tracking.

## Features

- Interactive OpenStreetMap integration
- Real-time user location tracking
- Multiple map styles (Streets, Topographic, Dark, Satellite)
- Custom map markers with different types and clustering
- Route tracking and recording
- Route statistics (distance, duration, average speed)
- Saved routes history with favorites
- Modern Material Design UI

## Getting Started

### Prerequisites

- Flutter SDK (version 3.19.6 or newer)
- Dart SDK (version 3.3.4 or newer)
- Android Studio / VS Code with Flutter extensions
- Android SDK (for Android development)
- Xcode (for iOS development)

### Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/osm_app.git
```

2. Navigate to the project folder:
```bash
cd osm_app
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Usage

### Map Screen
- Explore the map with gestures (pan, zoom)
- Toggle location tracking
- Change map style
- Add and manage custom markers

### Route Tracker
- Start tracking a new route
- View real-time statistics
- Save completed routes

### Saved Routes
- View list of previously saved routes
- Check route details and statistics
- Mark favorite routes
- Share routes with others

## Dependencies

- flutter_map: For OpenStreetMap integration
- latlong2: For geographical coordinates
- geolocator: For device location
- permission_handler: For managing permissions
- flutter_map_marker_cluster: For clustering markers
- shared_preferences: For local storage
- intl: For date formatting
- uuid: For generating unique IDs

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenStreetMap contributors for the map data
- Flutter and Dart teams for the amazing framework
