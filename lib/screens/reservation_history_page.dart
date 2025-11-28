import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationHistoryPage extends StatelessWidget {
  final User? user;

  const ReservationHistoryPage({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historique des Réservations')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Historique en développement',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
