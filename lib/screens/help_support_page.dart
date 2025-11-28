import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  final User? user;

  const HelpSupportPage({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Aide & Support')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSupportCard(
              icon: Icons.help,
              title: 'FAQ',
              subtitle: 'Questions fréquemment posées',
              onTap: () {
                // Naviguer vers FAQ
              },
            ),

            _buildSupportCard(
              icon: Icons.phone,
              title: 'Contactez-nous',
              subtitle: 'Service client 24/7',
              onTap: () {
                _launchPhone('+33123456789');
              },
            ),

            _buildSupportCard(
              icon: Icons.email,
              title: 'Email support',
              subtitle: 'support@smartparking.com',
              onTap: () {
                _launchEmail('support@smartparking.com');
              },
            ),

            _buildSupportCard(
              icon: Icons.chat,
              title: 'Chat en direct',
              subtitle: 'Disponible 9h-18h',
              onTap: () {
                // Ouvrir chat
              },
            ),

            SizedBox(height: 30),
            Text(
              'Questions Fréquentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  _buildFAQItem(
                    question: 'Comment réserver une place de parking ?',
                    answer:
                        'Allez dans la carte, sélectionnez un parking et suivez les instructions.',
                  ),
                  _buildFAQItem(
                    question: 'Puis-je annuler ma réservation ?',
                    answer:
                        'Oui, jusqu\'à 30 minutes avant l\'heure de réservation.',
                  ),
                  _buildFAQItem(
                    question: 'Comment fonctionne le paiement ?',
                    answer:
                        'Le paiement est sécurisé et s\'effectue via votre carte enregistrée.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue, size: 30),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(question, style: TextStyle(fontWeight: FontWeight.w500)),
        children: [Padding(padding: EdgeInsets.all(16), child: Text(answer))],
      ),
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _launchEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
