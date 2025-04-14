import 'package:flutter/material.dart';
import '../models/user_stats.dart';
import '../models/user_profile.dart';
import '../services/pdf_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use dummy stats for demonstration
    final UserStats stats = UserStats.dummy();
    final UserProfile profile = UserProfile.dummy();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _downloadPdfReport(context, stats, profile.name),
            tooltip: 'Download PDF Report',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(context, stats),
              const SizedBox(height: 24),
              _buildWeeklyActivityChart(context, stats),
              const SizedBox(height: 24),
              _buildMonthlyActivityChart(context, stats),
              const SizedBox(height: 24),
              _buildDetailedStats(context, stats),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Handle PDF report generation and download
  Future<void> _downloadPdfReport(BuildContext context, UserStats stats, String userName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF report...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      final pdfService = PdfService();
      final pdfFile = await pdfService.generateDashboardReport(stats, userName);
      
      await pdfService.openPdf(pdfFile);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF report generated successfully'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSummaryCards(BuildContext context, UserStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Summary',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              'Total Distance',
              '${stats.totalDistance.toStringAsFixed(1)} km',
              Icons.straighten,
              Colors.blue,
            ),
            _buildStatCard(
              context,
              'Routes Tracked',
              stats.totalRoutes.toString(),
              Icons.route,
              Colors.green,
            ),
            _buildStatCard(
              context,
              'Time Active',
              _formatDuration(stats.totalDuration),
              Icons.timer,
              Colors.orange,
            ),
            _buildStatCard(
              context,
              'Calories Burned',
              '${stats.caloriesBurned} kcal',
              Icons.local_fire_department,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyActivityChart(BuildContext context, UserStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Activity',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _buildBarChart(
            context, 
            stats.weeklyActivity,
            maxValue: stats.weeklyActivity.values.fold<double>(0, (max, value) => value > max ? value : max) * 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyActivityChart(BuildContext context, UserStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Activity',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _buildBarChart(
            context, 
            stats.monthlyActivity,
            maxValue: stats.monthlyActivity.values.fold<double>(0, (max, value) => value > max ? value : max) * 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(
    BuildContext context, 
    Map<String, double> data, 
    {required double maxValue}
  ) {
    final theme = Theme.of(context);
    final barColor = theme.colorScheme.primary;
    
    return ListView(
      scrollDirection: Axis.horizontal,
      children: data.entries.map((entry) {
        final value = entry.value;
        final label = entry.key;
        final barHeight = value > 0 ? (value / maxValue) * 150.0 : 0.0;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: barHeight,
                width: 24,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value.toStringAsFixed(1),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailedStats(BuildContext context, UserStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Statistics',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDetailRow(
                  context, 
                  'Average Speed', 
                  '${stats.averageSpeed.toStringAsFixed(1)} km/h'
                ),
                _buildDetailRow(
                  context, 
                  'Maximum Speed', 
                  '${stats.maxSpeed.toStringAsFixed(1)} km/h'
                ),
                _buildDetailRow(
                  context, 
                  'Total Steps', 
                  NumberFormat.decimalPattern().format(stats.totalSteps)
                ),
                _buildDetailRow(
                  context, 
                  'Average Distance per Route', 
                  '${(stats.totalDistance / stats.totalRoutes).toStringAsFixed(1)} km'
                ),
                _buildDetailRow(
                  context, 
                  'Average Time per Route', 
                  _formatDuration(Duration(minutes: stats.totalDuration.inMinutes ~/ stats.totalRoutes))
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
} 