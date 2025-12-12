import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Ajoutez ceci

class MesReservationsPage extends StatefulWidget {
  const MesReservationsPage({super.key});

  @override
  State<MesReservationsPage> createState() => _MesReservationsPageState();
}

class _MesReservationsPageState extends State<MesReservationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance
      .ref(); // Ajoutez ceci

  // -------------------------------------------------------------
  // Annuler la réservation si elle est encore dans le délai permis
  // -------------------------------------------------------------
  Future<void> _cancelReservation(
    BuildContext context,
    String id,
    String spotId,
    DateTime reservationDateTime,
  ) async {
    final now = DateTime.now();
    final difference = now.difference(reservationDateTime);

    if (difference.inMinutes > 30) {
      // Au-delà de 30 minutes → annulation impossible
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Annulation impossible"),
          content: const Text(
            "Vous ne pouvez plus annuler cette réservation.\n(30 minutes dépassées)",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    try {
      // 1. Marquer comme annulée DANS FIRESTORE
      await _firestore.collection('reservations').doc(id).update({
        'status': 'cancelled',
      });

      // 2. Libérer la place DANS REALTIME DATABASE
      try {
        // Vérifier si la place existe dans Realtime Database
        final spotSnapshot = await _database
            .child('parking_spots')
            .child(spotId)
            .get();

        if (spotSnapshot.exists) {
          // Mettre à jour la place dans Realtime Database
          await _database.child('parking_spots').child(spotId).update({
            'isOccupied': false,
            'status': 'free',
            'lastUpdated': ServerValue.timestamp,
          });
          print("✅ Place $spotId libérée dans Realtime Database");
        } else {
          // Créer la place si elle n'existe pas
          await _database.child('parking_spots').child(spotId).set({
            'id': spotId,
            'isOccupied': false,
            'status': 'free',
            'createdAt': ServerValue.timestamp,
            'lastUpdated': ServerValue.timestamp,
          });
          print("✅ Place $spotId créée comme libre dans Realtime Database");
        }
      } catch (e) {
        print(
          "⚠️ Erreur lors de la libération de la place dans Realtime Database: $e",
        );
        // On peut continuer même si la mise à jour de la place échoue
      }

      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Réservation annulée"),
          content: const Text("Votre réservation a été annulée avec succès."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Erreur"),
          content: Text("Impossible d'annuler : $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  String _formatDateTimeFrench(DateTime dateTime) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}h${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Fonction pour formater creationDate (peut être String ou Timestamp)
  String _formatCreationDate(dynamic creationDateField) {
    if (creationDateField == null) {
      return 'Non disponible';
    } else if (creationDateField is String) {
      return creationDateField;
    } else if (creationDateField is Timestamp) {
      return _formatDateTimeFrench(creationDateField.toDate());
    } else {
      return creationDateField.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mes réservations")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Veuillez vous connecter pour voir vos réservations.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes réservations"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('reservations')
            .where('email', isEqualTo: user.email)
            .orderBy('reservationDateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Debug: Voir l'état du snapshot
          print('Snapshot state: ${snapshot.connectionState}');
          print('Snapshot has data: ${snapshot.hasData}');
          print('Snapshot has error: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('Snapshot error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Chargement de vos réservations...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "Erreur de chargement",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "Erreur : ${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text("Réessayer"),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Vous n'avez aucune réservation.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Réservez une place pour la voir apparaître ici.",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return RefreshIndicator(
            onRefresh: () async {
              // Force un refresh
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final id = docs[index].id;
                final spotId = data['spotId'] ?? 'N/A';
                final status = data['status'] ?? 'unknown';
                final duration = data['duration'] ?? 0;
                final price = data['price'] ?? 0;
                final licensePlate = data['licensePlate'] ?? 'N/A';
                final creationDateField = data['creationDate'];

                // Récupération de la date de réservation
                DateTime reservationDateTime;
                final reservationDateField = data['reservationDateTime'];

                if (reservationDateField == null) {
                  reservationDateTime = DateTime.now();
                } else if (reservationDateField is Timestamp) {
                  reservationDateTime = reservationDateField.toDate();
                } else if (reservationDateField is String) {
                  try {
                    reservationDateTime = DateTime.parse(reservationDateField);
                  } catch (e) {
                    print('Error parsing date string: $e');
                    reservationDateTime = DateTime.now();
                  }
                } else {
                  reservationDateTime = DateTime.now();
                }

                // Formatage de la date de création
                final formattedCreationDate = _formatCreationDate(
                  creationDateField,
                );

                // Calcul minutes écoulées depuis la réservation
                final elapsed = DateTime.now()
                    .difference(reservationDateTime)
                    .inMinutes;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_parking,
                                    size: 30,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      "Place $spotId",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: status == "confirmed"
                                    ? Colors.green[50]
                                    : status == "cancelled"
                                    ? Colors.red[50]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: status == "confirmed"
                                      ? Colors.green[300] ?? Colors.green
                                      : status == "cancelled"
                                      ? Colors.red[300] ?? Colors.red
                                      : Colors.grey[300] ?? Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                status == "confirmed"
                                    ? "CONFIRMÉE"
                                    : status == "cancelled"
                                    ? "ANNULÉE"
                                    : status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: status == "confirmed"
                                      ? Colors.green[800] ?? Colors.green
                                      : status == "cancelled"
                                      ? Colors.red[800] ?? Colors.red
                                      : Colors.grey[800] ?? Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Informations de réservation
                        _buildInfoRow(
                          Icons.calendar_today,
                          "Date/heure :",
                          _formatDateTimeFrench(reservationDateTime),
                        ),
                        _buildInfoRow(
                          Icons.timer,
                          "Durée :",
                          "$duration heure(s)",
                        ),
                        _buildInfoRow(Icons.euro, "Prix :", "$price €"),
                        _buildInfoRow(
                          Icons.directions_car,
                          "Plaque :",
                          licensePlate,
                        ),
                        _buildInfoRow(
                          Icons.create,
                          "Créée le :",
                          formattedCreationDate,
                        ),

                        if (status == "confirmed") ...[
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey[300], height: 1),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: elapsed > 30
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Temps écoulé : $elapsed min",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: elapsed > 30
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                              const Spacer(),
                              if (elapsed <= 30)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () => _cancelReservation(
                                    context,
                                    id,
                                    spotId,
                                    reservationDateTime,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cancel, size: 18),
                                      SizedBox(width: 6),
                                      Text("Annuler"),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700] ?? Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700] ?? Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
