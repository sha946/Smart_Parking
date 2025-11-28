import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyVehiclesPage extends StatelessWidget {
  final User? user;

  const MyVehiclesPage({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mes Véhicules')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Gestion véhicules en développement',
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
