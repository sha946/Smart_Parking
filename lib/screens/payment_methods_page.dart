import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentMethodsPage extends StatelessWidget {
  final User? user;

  const PaymentMethodsPage({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moyens de Paiement'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Ajouter une carte
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cartes enregistrées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Exemple de carte
            _buildPaymentCard(
              cardType: 'Visa',
              lastDigits: '4242',
              expiryDate: '12/25',
            ),

            _buildPaymentCard(
              cardType: 'MasterCard',
              lastDigits: '8888',
              expiryDate: '08/24',
            ),

            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Ajouter une carte'),
                onPressed: () {
                  // Ajouter nouvelle carte
                },
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Retour'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required String cardType,
    required String lastDigits,
    required String expiryDate,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.credit_card, color: Colors.blue, size: 40),
        title: Text('$cardType •••• $lastDigits'),
        subtitle: Text('Expire le $expiryDate'),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            // Supprimer la carte
          },
        ),
      ),
    );
  }
}
