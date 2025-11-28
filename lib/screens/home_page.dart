import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import 'admin_dashboard.dart';
import 'profile_page.dart';
import 'maps_page.dart';

class HomePage extends StatelessWidget {
  final AuthService _auth = AuthService();
  final bool isAdmin;
  final User? currentUser;

  HomePage({super.key, required this.isAdmin, this.currentUser});

  @override
  Widget build(BuildContext context) {
    String displayName =
        currentUser?.displayName ??
        currentUser?.email?.split('@')[0] ??
        'Utilisateur';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Tableau de Bord Admin' : 'Accueil Smart Parking',
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          // User greeting
          Padding(padding: EdgeInsets.only(right: 16.0, top: 16.0)),

          // Admin Dashboard button (only for admins)
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              tooltip: 'Tableau de Bord Admin',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDashboard(
                      user: currentUser,
                    ), // ← CONSISTENT: use 'user'
                  ),
                );
              },
            ),

          // Map button
          IconButton(
            icon: Icon(Icons.map),
            tooltip: 'Map du parking',
            onPressed: () {
              Navigator.pushNamed(context, '/maps');
            },
          ),

          // Profile button

          // Logout button
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User avatar with display name
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue[100],
              child: Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 60,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),

            // Welcome message with user name
            Text(
              isAdmin
                  ? 'Bienvenue Admin $displayName!'
                  : 'Bienvenue $displayName!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 10),
            Text(
              currentUser?.email ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            SizedBox(height: 20),

            // Role badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.red[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAdmin ? 'ADMINISTRATEUR' : 'UTILISATEUR',
                style: TextStyle(
                  color: isAdmin ? Colors.red[800] : Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 30),

            // Quick actions
            if (isAdmin) ...[
              _buildActionButton(
                icon: Icons.admin_panel_settings,
                label: 'Tableau de Bord Admin',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminDashboard(
                        user: currentUser,
                      ), // ← CONSISTENT: use 'user'
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
            ],

            _buildActionButton(
              icon: Icons.map,
              label: 'Explorer le Parking',
              onPressed: () {
                Navigator.pushNamed(context, '/maps');
              },
            ),
            SizedBox(height: 10),

            _buildActionButton(
              icon: Icons.person,
              label: 'Mon Profil',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      user: currentUser,
                    ), // ← CONSISTENT: use 'user'
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 250,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
