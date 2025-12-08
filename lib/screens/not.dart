import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, String>> notifications = [];

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((msg) {
      setState(() {
        notifications.insert(0, {
          "title": msg.notification?.title ?? "Notification",
          "body": msg.notification?.body ?? "",
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: notifications.isEmpty
          ? const Center(child: Text("Aucune notification pour le moment"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, i) {
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(notifications[i]["title"]!),
                  subtitle: Text(notifications[i]["body"]!),
                );
              },
            ),
    );
  }
}
