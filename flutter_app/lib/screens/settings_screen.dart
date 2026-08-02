import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ApiService.instance.baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Backend Server URL', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          const Text(
            'On the same WiFi as your laptop, find your laptop IP (run `ipconfig` on Windows or `ifconfig` on Mac/Linux) and enter it here, e.g. http://192.168.1.5:8000',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Server URL')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await ApiService.instance.setBaseUrl(_urlCtrl.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server URL saved')));
            },
            child: const Text('Save'),
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          const Text('How to connect phone to laptop', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            '1. Make sure both devices are on the same WiFi\n'
            '2. On your laptop, run: powershell ./run.ps1 -HostNetwork (or ./run.sh --host)\n'
            '3. Find your laptop\'s local IP address (ipconfig)\n'
            '4. Enter http://<your-laptop-ip>:8000 above',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
