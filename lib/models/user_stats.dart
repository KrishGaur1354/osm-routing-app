class UserStats {
  final double totalDistance; // in kilometers
  final int totalRoutes;
  final Duration totalDuration;
  final double averageSpeed; // in km/h
  final double maxSpeed; // in km/h
  final int caloriesBurned;
  final int totalSteps;
  final Map<String, double> weeklyActivity; // day -> distance
  final Map<String, double> monthlyActivity; // month -> distance

  UserStats({
    required this.totalDistance,
    required this.totalRoutes,
    required this.totalDuration,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.caloriesBurned,
    required this.totalSteps,
    required this.weeklyActivity,
    required this.monthlyActivity,
  });

  // Dummy data for demonstration
  factory UserStats.dummy() {
    return UserStats(
      totalDistance: 156.8,
      totalRoutes: 24,
      totalDuration: const Duration(hours: 18, minutes: 45),
      averageSpeed: 8.4,
      maxSpeed: 15.2,
      caloriesBurned: 12450,
      totalSteps: 195000,
      weeklyActivity: {
        'Mon': 5.2,
        'Tue': 0.0,
        'Wed': 8.7,
        'Thu': 4.3,
        'Fri': 0.0,
        'Sat': 12.5,
        'Sun': 6.8,
      },
      monthlyActivity: {
        'Jan': 48.5,
        'Feb': 52.7,
        'Mar': 25.6,
        'Apr': 30.0,
        'May': 0.0,
        'Jun': 0.0,
        'Jul': 0.0,
        'Aug': 0.0,
        'Sep': 0.0,
        'Oct': 0.0,
        'Nov': 0.0,
        'Dec': 0.0,
      },
    );
  }
} 