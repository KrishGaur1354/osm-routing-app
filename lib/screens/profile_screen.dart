import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserProfile _profile = UserProfile.dummy();
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    // Initialize settings from profile
    _settings = Map<String, dynamic>.from(_profile.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 20),
            _buildInfoSection(context),
            const SizedBox(height: 20),
            _buildSettingsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: _profile.avatarUrl != null
                ? null
                : Text(
                    _profile.name.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            _profile.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _profile.email,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Member since ${DateFormat.yMMMM().format(_profile.joinDate)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_profile.bio != null) ...[
            const SizedBox(height: 16),
            Text(
              _profile.bio!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    'Height',
                    '${_profile.height.toStringAsFixed(1)} cm',
                    Icons.height,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    'Weight',
                    '${_profile.weight.toStringAsFixed(1)} kg',
                    Icons.fitness_center,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    'Location',
                    _profile.location,
                    Icons.location_on,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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

  Widget _buildSettingsSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildSwitchTile(
                    context,
                    'Dark Mode',
                    themeProvider.darkTheme,
                    Icons.dark_mode,
                    (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                  _buildSwitchTile(
                    context,
                    'Enable Notifications',
                    _settings['notifications'] as bool,
                    Icons.notifications,
                    (value) {
                      setState(() {
                        _settings['notifications'] = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    context,
                    'Location Tracking',
                    _settings['locationTracking'] as bool,
                    Icons.location_on,
                    (value) {
                      setState(() {
                        _settings['locationTracking'] = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    context,
                    'Data Sync',
                    _settings['dataSync'] as bool,
                    Icons.sync,
                    (value) {
                      setState(() {
                        _settings['dataSync'] = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDropdownTile(
                    context,
                    'Units',
                    _settings['units'] as String,
                    Icons.straighten,
                    ['metric', 'imperial'],
                    (String? value) {
                      if (value != null) {
                        setState(() {
                          _settings['units'] = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDropdownTile(
                    context,
                    'Map Style',
                    _settings['mapStyle'] as String,
                    Icons.map,
                    ['streets', 'satellite', 'topographic', 'dark'],
                    (String? value) {
                      if (value != null) {
                        setState(() {
                          _settings['mapStyle'] = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings saved successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Text(title),
        ],
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        DropdownButton<String>(
          value: value,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option.substring(0, 1).toUpperCase() + option.substring(1),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
} 