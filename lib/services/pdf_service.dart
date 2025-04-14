import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

import '../models/user_stats.dart';
import '../models/route.dart';

class PdfService {
  // Singleton pattern
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // Generate a PDF report for the user dashboard
  Future<File> generateDashboardReport(UserStats stats, String userName) async {
    final pdf = pw.Document();
    
    // Load fonts
    final regularFont = await rootBundle.load("assets/fonts/Montserrat-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Montserrat-Bold.ttf");
    final semiBoldFont = await rootBundle.load("assets/fonts/Montserrat-SemiBold.ttf");
    
    final ttfRegular = pw.Font.ttf(regularFont);
    final ttfBold = pw.Font.ttf(boldFont);
    final ttfSemiBold = pw.Font.ttf(semiBoldFont);

    final dateFormatter = DateFormat('MMMM dd, yyyy');
    final currentDate = dateFormatter.format(DateTime.now());
    
    // Add content to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          context, 
          'Activity Dashboard', 
          'Generated on $currentDate',
          ttfBold,
          ttfRegular,
        ),
        footer: (context) => _buildFooter(context, ttfRegular),
        build: (context) => [
          // User info
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'User Report: $userName',
                  style: pw.TextStyle(
                    font: ttfSemiBold,
                    fontSize: 18,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'This report summarizes your activity statistics and performance.',
                  style: pw.TextStyle(
                    font: ttfRegular,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          
          // Summary statistics
          pw.Header(
            level: 1,
            text: 'Activity Summary',
            textStyle: pw.TextStyle(font: ttfSemiBold, fontSize: 16),
          ),
          pw.SizedBox(height: 10),
          _buildSummaryGrid(stats, ttfRegular, ttfSemiBold),
          pw.SizedBox(height: 30),
          
          // Weekly activity
          pw.Header(
            level: 1,
            text: 'Weekly Activity',
            textStyle: pw.TextStyle(font: ttfSemiBold, fontSize: 16),
          ),
          pw.SizedBox(height: 10),
          _buildBarChart(stats.weeklyActivity, ttfRegular),
          pw.SizedBox(height: 30),
          
          // Monthly activity
          pw.Header(
            level: 1,
            text: 'Monthly Activity',
            textStyle: pw.TextStyle(font: ttfSemiBold, fontSize: 16),
          ),
          pw.SizedBox(height: 10),
          _buildBarChart(stats.monthlyActivity, ttfRegular),
          pw.SizedBox(height: 30),
          
          // Detailed statistics
          pw.Header(
            level: 1,
            text: 'Detailed Statistics',
            textStyle: pw.TextStyle(font: ttfSemiBold, fontSize: 16),
          ),
          pw.SizedBox(height: 10),
          _buildDetailedStats(stats, ttfRegular, ttfSemiBold),
        ],
      ),
    );
    
    // Save the PDF to a file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/dashboard_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  // Generate a PDF report for a specific route
  Future<File> generateRouteReport(RouteTrack route) async {
    final pdf = pw.Document();
    
    // Load fonts
    final regularFont = await rootBundle.load("assets/fonts/Montserrat-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Montserrat-Bold.ttf");
    final semiBoldFont = await rootBundle.load("assets/fonts/Montserrat-SemiBold.ttf");
    
    final ttfRegular = pw.Font.ttf(regularFont);
    final ttfBold = pw.Font.ttf(boldFont);
    final ttfSemiBold = pw.Font.ttf(semiBoldFont);

    final dateFormatter = DateFormat('MMMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    
    final routeDate = dateFormatter.format(route.startTime);
    final startTime = timeFormatter.format(route.startTime);
    final endTime = route.endTime != null ? timeFormatter.format(route.endTime!) : 'In Progress';
    
    // Add content to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          context, 
          'Route Report', 
          route.name,
          ttfBold,
          ttfRegular,
        ),
        footer: (context) => _buildFooter(context, ttfRegular),
        build: (context) => [
          // Route info
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Date: $routeDate',
                  style: pw.TextStyle(font: ttfRegular, fontSize: 12),
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Start: $startTime',
                        style: pw.TextStyle(font: ttfRegular, fontSize: 12),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'End: $endTime',
                        style: pw.TextStyle(font: ttfRegular, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (route.description != null && route.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'Description:',
                    style: pw.TextStyle(font: ttfSemiBold, fontSize: 12),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    route.description!,
                    style: pw.TextStyle(font: ttfRegular, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          
          // Route summary
          pw.Header(
            level: 1,
            text: 'Route Summary',
            textStyle: pw.TextStyle(font: ttfSemiBold, fontSize: 16),
          ),
          pw.SizedBox(height: 10),
          _buildRouteStatGrid(route, ttfRegular, ttfSemiBold),
        ],
      ),
    );
    
    // Save the PDF to a file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/route_report_${route.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  // Open a PDF file
  Future<void> openPdf(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open PDF: ${result.message}');
    }
  }

  // Build the header for the PDF report
  pw.Widget _buildHeader(
    pw.Context context,
    String title,
    String subtitle,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(font: boldFont, fontSize: 20),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            'OSM Explorer',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: PdfColors.blue800,
            ),
          ),
        ],
      ),
    );
  }

  // Build the footer for the PDF report
  pw.Widget _buildFooter(pw.Context context, pw.Font regularFont) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColors.grey300)),
      ),
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by OSM Explorer App',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  // Build a grid of summary statistics
  pw.Widget _buildSummaryGrid(UserStats stats, pw.Font regularFont, pw.Font semiBoldFont) {
    final formatDuration = (Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return hours > 0 ? '$hours h ${minutes > 0 ? '$minutes min' : ''}' : '$minutes min';
    };

    return pw.GridView(
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      children: [
        _buildStatItem('Total Distance', '${stats.totalDistance.toStringAsFixed(1)} km', regularFont, semiBoldFont),
        _buildStatItem('Routes Tracked', stats.totalRoutes.toString(), regularFont, semiBoldFont),
        _buildStatItem('Time Active', formatDuration(stats.totalDuration), regularFont, semiBoldFont),
        _buildStatItem('Calories Burned', '${stats.caloriesBurned} kcal', regularFont, semiBoldFont),
      ],
    );
  }

  // Build a grid of route-specific statistics
  pw.Widget _buildRouteStatGrid(RouteTrack route, pw.Font regularFont, pw.Font semiBoldFont) {
    final formatDuration = (Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return hours > 0 ? '$hours h ${minutes > 0 ? '$minutes min' : ''}' : '$minutes min';
    };

    final distanceKm = route.totalDistance / 1000;
    
    return pw.GridView(
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      children: [
        _buildStatItem('Total Distance', '${distanceKm.toStringAsFixed(1)} km', regularFont, semiBoldFont),
        _buildStatItem('Duration', formatDuration(route.duration), regularFont, semiBoldFont),
        _buildStatItem('Average Speed', '${route.averageSpeed.toStringAsFixed(1)} km/h', regularFont, semiBoldFont),
        _buildStatItem('Points Recorded', route.points.length.toString(), regularFont, semiBoldFont),
      ],
    );
  }

  // Build a statistics item for the grids
  pw.Widget _buildStatItem(String label, String value, pw.Font regularFont, pw.Font semiBoldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      margin: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: semiBoldFont,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Build a bar chart for weekly or monthly activity
  pw.Widget _buildBarChart(Map<String, double> data, pw.Font regularFont) {
    final maxValue = data.values.reduce((max, value) => value > max ? value : max);
    
    return pw.Container(
      height: 180,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: data.entries.map((entry) {
          final value = entry.value;
          final label = entry.key;
          final barHeight = value > 0 ? (value / maxValue) * 150.0 : 0.0;
          
          return pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  height: barHeight,
                  width: 15,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue400,
                    borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(2)),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  label,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 8,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  value.toStringAsFixed(1),
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build detailed statistics section
  pw.Widget _buildDetailedStats(UserStats stats, pw.Font regularFont, pw.Font semiBoldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          _buildDetailRow('Average Speed', '${stats.averageSpeed.toStringAsFixed(1)} km/h', regularFont, semiBoldFont),
          pw.Divider(height: 15),
          _buildDetailRow('Maximum Speed', '${stats.maxSpeed.toStringAsFixed(1)} km/h', regularFont, semiBoldFont),
          pw.Divider(height: 15),
          _buildDetailRow('Total Steps', NumberFormat.decimalPattern().format(stats.totalSteps), regularFont, semiBoldFont),
          pw.Divider(height: 15),
          _buildDetailRow('Average Distance per Route', 
            '${(stats.totalDistance / stats.totalRoutes).toStringAsFixed(1)} km', regularFont, semiBoldFont),
        ],
      ),
    );
  }

  // Build a detail row for the detailed statistics section
  pw.Widget _buildDetailRow(String label, String value, pw.Font regularFont, pw.Font semiBoldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 12,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: semiBoldFont,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 