import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import 'login_page.dart';

// Pages imports - vous devrez créer ces fichiers séparément
import 'reservation_history_page.dart';
import 'my_vehicles_page.dart';
import 'notifications_page.dart';
import 'payment_methods_page.dart';
import 'settings_page.dart';
import 'help_support_page.dart';

class ProfilePage extends StatefulWidget {
  final User? user;

  const ProfilePage({Key? key, this.user}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current display name or email username as fallback
    _nameController.text = _getDisplayName();
  }

  String _getDisplayName() {
    final user = widget.user;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'Utilisateur';
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Le nom ne peut pas être vide')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateUserProfile(
        displayName: _nameController.text.trim(),
      );
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profil mis à jour avec succès')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _nameController.text = _getDisplayName();
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameController.text = _getDisplayName();
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final displayName = _getDisplayName(); // Use the helper method
    final email = user?.email ?? '';
    final isAdmin = AuthService.isAdmin(user!);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mon Profil',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _startEditing,
              tooltip: 'Modifier le profil',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header avec avatar
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            size: 50,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Display Name (editable)
                        _isEditing
                            ? TextFormField(
                                controller: _nameController,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: 'Entrez votre nom',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              )
                            : Text(
                                displayName, // This will show the actual name
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                        SizedBox(height: 8),
                        Text(
                          email,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),

                        SizedBox(height: 8),
                        // Role badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? Colors.red[300]
                                : Colors.green[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAdmin ? 'ADMINISTRATEUR' : 'UTILISATEUR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Edit buttons when editing
                  if (_isEditing) ...[
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              child: Text('Sauvegarder'),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelEditing,
                              child: Text('Annuler'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                  ],

                  // Menu options - BOUTONS CONFIGURÉS
                  ListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      _buildMenuItem(
                        icon: Icons.history,
                        title: 'Historique des stationnements',
                        subtitle: 'Voir mes stationnements précédents',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ParkingHistoryPage(user: user),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.directions_car,
                        title: 'Mes véhicules',
                        subtitle: 'Gérer mes véhicules enregistrés',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyVehiclesPage(user: user),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Paramètres des alertes',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NotificationsPage(user: user),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.payment,
                        title: 'Moyens de paiement',
                        subtitle: 'Gérer mes cartes de paiement',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PaymentMethodsPage(user: user),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.settings,
                        title: 'Paramètres',
                        subtitle: 'Configuration du compte',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsPage(user: user),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.help,
                        title: 'Aide & Support',
                        subtitle: 'FAQ et contact support',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HelpSupportPage(user: user),
                            ),
                          );
                        },
                      ),
                      Divider(),
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: 'Déconnexion',
                        subtitle: 'Se déconnecter du compte',
                        onTap: _logout,
                        textColor: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.blue),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

// Page historique des stationnements
class ParkingHistoryPage extends StatelessWidget {
  final User user;

  const ParkingHistoryPage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historique des Stationnements')),
      body: ListView.builder(
        itemCount: 5, // Exemple
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.local_parking, color: Colors.blue),
              ),
              title: Text(
                'Place ${String.fromCharCode(65 + index)}${index + 1}',
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Centre Commercial ${index + 1}'),
                  Text(
                    '${DateTime.now().subtract(Duration(days: index * 2))}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(index + 1) * 30} min',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(index + 1) * 2}€',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
