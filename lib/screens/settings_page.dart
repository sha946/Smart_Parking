import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/theme_manager.dart';

class SettingsPage extends StatefulWidget {
  final User? user;

  const SettingsPage({Key? key, this.user}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricAuth = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  String _language = 'Français';

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
          // SECTION APPAREIL
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

          // SECTION NOTIFICATIONS
          _buildSectionHeader('Notifications', isDarkMode),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications push',
            subtitle: 'Recevoir des notifications push',
            isDarkMode: isDarkMode,
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
                _showSnackbar(
                  'Notifications push ${value ? 'activées' : 'désactivées'}',
                  isDarkMode,
                );
              },
            ),
          ),

          _buildSettingsTile(
            icon: Icons.email,
            title: 'Notifications email',
            subtitle: 'Recevoir des emails',
            isDarkMode: isDarkMode,
            trailing: Switch(
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
                _showSnackbar(
                  'Notifications email ${value ? 'activées' : 'désactivées'}',
                  isDarkMode,
                );
              },
            ),
          ),

          // SECTION PRÉFÉRENCES
          _buildSectionHeader('Préférences', isDarkMode),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Langue',
            subtitle: _language,
            isDarkMode: isDarkMode,
            trailing: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
            onTap: () {
              _showLanguageDialog(context, isDarkMode);
            },
          ),

          // SECTION SÉCURITÉ
          _buildSectionHeader('Sécurité', isDarkMode),
          _buildSettingsTile(
            icon: Icons.fingerprint,
            title: 'Authentification biométrique',
            subtitle: 'Déverrouiller avec empreinte/visage',
            isDarkMode: isDarkMode,
            trailing: Switch(
              value: _biometricAuth,
              onChanged: (value) {
                setState(() {
                  _biometricAuth = value;
                });
                _showSnackbar(
                  'Authentification biométrique ${value ? 'activée' : 'désactivée'}',
                  isDarkMode,
                );
              },
            ),
          ),

          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Changer le mot de passe',
            subtitle: 'Mettre à jour votre mot de passe',
            isDarkMode: isDarkMode,
            trailing: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
            onTap: () {
              _showChangePasswordDialog(context, isDarkMode);
            },
          ),

          _buildSettingsTile(
            icon: Icons.security,
            title: 'Confidentialité',
            subtitle: 'Paramètres de confidentialité',
            isDarkMode: isDarkMode,
            trailing: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
            onTap: () {
              _showPrivacyDialog(context, isDarkMode);
            },
          ),

          // SECTION COMPTE
          _buildSectionHeader('Compte', isDarkMode),
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Informations du compte',
            subtitle: 'Modifier vos informations personnelles',
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

          _buildSettingsTile(
            icon: Icons.assignment,
            title: 'Conditions d\'utilisation',
            subtitle: 'Lire les conditions',
            isDarkMode: isDarkMode,
            trailing: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
            onTap: () {
              _launchUrl('https://votre-site.com/conditions');
            },
          ),

          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Politique de confidentialité',
            subtitle: 'Comment nous utilisons vos données',
            isDarkMode: isDarkMode,
            trailing: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
            onTap: () {
              _launchUrl('https://votre-site.com/confidentialite');
            },
          ),

          _buildSettingsTile(
            icon: Icons.star,
            title: 'Noter l\'application',
            subtitle: 'Donnez votre avis sur le store',
            isDarkMode: isDarkMode,
            trailing: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
            onTap: () {
              _showRateAppDialog(context, isDarkMode);
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

  // DIALOGUES ET FONCTIONS
  void _showLanguageDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choisir la langue'),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(
              'Français',
              'français',
              Icons.language,
              isDarkMode,
            ),
            _buildDialogOption(
              'English',
              'english',
              Icons.language,
              isDarkMode,
            ),
            _buildDialogOption(
              'Español',
              'espanol',
              Icons.language,
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOption(
    String text,
    String value,
    IconData icon,
    bool isDarkMode,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        text,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      trailing: _getCurrentValue(value)
          ? Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        setState(() {
          _updateSetting(value, text);
        });
        Navigator.pop(context);
        _showSnackbar('$text sélectionné', isDarkMode);
      },
    );
  }

  bool _getCurrentValue(String value) {
    if (value == _language.toLowerCase()) return true;
    return false;
  }

  void _updateSetting(String value, String displayText) {
    if (['français', 'english', 'espanol'].contains(value)) {
      _language = displayText;
    }
  }

  // DIALOGUES IMPORTANTS
  void _showChangePasswordDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le mot de passe'),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cette fonctionnalité sera disponible dans la prochaine mise à jour.',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confidentialité'),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Paramètres de confidentialité:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '• Partage de données: Désactivé',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '• Localisation: Uniquement pendant l\'utilisation',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
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
              setState(() {
                _language = 'Français';
                _biometricAuth = false;
                _emailNotifications = true;
                _pushNotifications = true;
              });
              Navigator.pop(context);
              _showSnackbar('Paramètres réinitialisés avec succès', isDarkMode);
            },
            child: Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _showRateAppDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Noter l\'application'),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        content: Text(
          'Merci d\'utiliser Smart Parking ! Voulez-vous nous noter sur le store ?',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Plus tard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(
                'https://play.google.com/store/apps/details?id=votre.package',
              );
            },
            child: Text('Noter'),
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
            Text(
              'Email: ${widget.user?.email ?? 'Non disponible'}',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            SizedBox(height: 10),
            Text(
              'Nom: ${widget.user?.displayName ?? 'Non défini'}',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            SizedBox(height: 10),
            Text(
              'UID: ${widget.user?.uid ?? 'Non disponible'}',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
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

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        _showSnackbar(
          'Impossible d\'ouvrir le lien',
          Provider.of<ThemeManager>(context, listen: false).themeMode ==
              ThemeMode.dark,
        );
      }
    } catch (e) {
      _showSnackbar(
        'Erreur lors de l\'ouverture du lien',
        Provider.of<ThemeManager>(context, listen: false).themeMode ==
            ThemeMode.dark,
      );
    }
  }
}
