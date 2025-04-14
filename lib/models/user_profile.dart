class UserProfile {
  final String name;
  final String email;
  final String? avatarUrl;
  final double weight; // in kg
  final double height; // in cm
  final String location;
  final String? bio;
  final DateTime joinDate;
  final Map<String, dynamic> settings;

  UserProfile({
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.weight,
    required this.height,
    required this.location,
    this.bio,
    required this.joinDate,
    required this.settings,
  });

  // Dummy data for demonstration
  factory UserProfile.dummy() {
    return UserProfile(
      name: "Beran",
      email: "beran.kekw@gmail.com",
      avatarUrl: null,
      weight: 80.5,
      height: 178.0,
      location: "Rohini, Delhi",
      bio: "Outdoor enthusiast and avid cyclist. Love exploring new trails and routes!",
      joinDate: DateTime(2025, 4, 15),
      settings: {
        "notifications": true,
        "locationTracking": true,
        "dataSync": true,
        "units": "metric",
        "mapStyle": "streets",
      },
    );
  }
} 