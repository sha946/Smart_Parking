import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  final User? user;

  const NotificationsPage({Key? key, this.user}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _parkingAlerts = true;
  bool _promotions = false;
  bool _securityAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres des notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            _buildNotificationSwitch(
              title: 'Alertes de parking',
              subtitle: 'Recevoir des alertes lorsque des places se libèrent',
              value: _parkingAlerts,
              onChanged: (value) {
                setState(() {
                  _parkingAlerts = value;
                });
              },
            ),

            _buildNotificationSwitch(
              title: 'Promotions et offres',
              subtitle: 'Recevoir des offres spéciales et promotions',
              value: _promotions,
              onChanged: (value) {
                setState(() {
                  _promotions = value;
                });
              },
            ),

            _buildNotificationSwitch(
              title: 'Alertes de sécurité',
              subtitle: 'Notifications importantes concernant la sécurité',
              value: _securityAlerts,
              onChanged: (value) {
                setState(() {
                  _securityAlerts = value;
                });
              },
            ),

            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Sauvegarder les paramètres'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(Icons.notifications, color: Colors.blue),
    );
  }
}
