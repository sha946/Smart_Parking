import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/theme_manager.dart';
import 'not.dart'; // ← ajoutés

class SettingsPage extends StatefulWidget {
  final User? user;

  const SettingsPage({Key? key, this.user}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final bool isDarkMode = themeManager.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres'),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue,
      ),
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // SECTION APPARENCE
          _buildSectionHeader('Apparence', isDarkMode),
          _buildSettingsTile(
            icon: Icons.dark_mode,
            title: 'Mode sombre',
            subtitle: 'Activer le thème sombre',
            isDarkMode: isDarkMode,
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                themeManager.toggleTheme(value);
                _showSnackbar(
                  'Mode sombre ${value ? 'activé' : 'désactivé'}',
                  isDarkMode,
                );
              },
            ),
          ),

          // SECTION COMPTE
          _buildSectionHeader('Compte', isDarkMode),
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Informations du compte',
            subtitle: 'Voir vos informations personnelles',
            isDarkMode: isDarkMode,
            trailing: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
            onTap: () {
              _showAccountInfo(context, isDarkMode);
            },
          ),

          _buildSettingsTile(
            icon: Icons.delete,
            title: 'Supprimer le compte',
            subtitle: 'Supprimer définitivement votre compte',
            isDarkMode: isDarkMode,
            trailing: Icon(Icons.chevron_right, color: Colors.red),
            onTap: () {
              _showDeleteAccountDialog(context, isDarkMode);
            },
          ),

          // SECTION À PROPOS
          _buildSectionHeader('À propos', isDarkMode),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'Version de l\'application',
            subtitle: '1.0.0 (Build 123)',
            isDarkMode: isDarkMode,
          ),
          _buildSectionHeader('Réservations', isDarkMode),

          _buildSettingsTile(
            icon: Icons.history,
            title: 'Historique de réservation',
            subtitle: 'Voir votre historique et notifications',
            isDarkMode: isDarkMode,
            trailing: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsPage()),
              );
            },
          ),

          // BOUTONS D'ACTION
          SizedBox(height: 30),
          _buildActionButton(
            text: 'Réinitialiser les paramètres',
            icon: Icons.restart_alt,
            color: Colors.orange,
            onPressed: () {
              _showResetSettingsDialog(context, isDarkMode);
            },
          ),

          SizedBox(height: 10),
          _buildActionButton(
            text: 'Exporter mes données',
            icon: Icons.download,
            color: Colors.green,
            onPressed: () {
              _showExportDataDialog(context, isDarkMode);
            },
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  // WIDGETS HELPER
  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.blue[200] : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // DIALOGUES
  void _showDeleteAccountDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le compte', style: TextStyle(color: Colors.red)),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible.',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackbar(
                'Suppression de compte - Contactez le support',
                isDarkMode,
              );
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Réinitialiser les paramètres'),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        content: Text(
          'Tous vos paramètres seront remis à zéro. Êtes-vous sûr ?',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final themeManager = Provider.of<ThemeManager>(
                context,
                listen: false,
              );
              themeManager.themeMode = ThemeMode.light;
              Navigator.pop(context);
              _showSnackbar('Paramètres réinitialisés avec succès', isDarkMode);
            },
            child: Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exporter mes données'),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        content: Text(
          'Vos données personnelles seront préparées pour le téléchargement. Cela peut prendre quelques minutes.',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackbar('Exportation des données démarrée', isDarkMode);
            },
            child: Text('Exporter'),
          ),
        ],
      ),
    );
  }

  void _showAccountInfo(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Informations du compte'),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Email',
              widget.user?.email ?? 'Non disponible',
              isDarkMode,
            ),
            SizedBox(height: 12),
            _buildInfoRow(
              'Nom',
              widget.user?.displayName ?? 'Non défini',
              isDarkMode,
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Text(
              'UID: ${widget.user?.uid ?? 'Non disponible'}',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.blue[200] : Colors.blue,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  // FONCTIONS UTILITAIRES
  void _showSnackbar(String message, bool isDarkMode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: isDarkMode ? Colors.grey[700] : Colors.blue,
      ),
    );
  }
}
