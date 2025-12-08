import 'package:flutter/material.dart';
import '../firebase_service.dart';
import '../models/parking_spot.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  final FirebaseService _service = FirebaseService();
  final User? user;

  AdminDashboard({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Tableau de Bord Admin',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATISTIQUES EN TEMPS RÉEL
            _buildRealTimeStats(isDarkMode),
            SizedBox(height: 30),

            // TITRE HISTORIQUE
            Text(
              'Historique des Réservations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16),

            // HISTORIQUE DES RÉSERVATIONS
            _buildReservationHistory(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeStats(bool isDarkMode) {
    return StreamBuilder<List<ParkingSpot>>(
      stream: _service.getParkingSpots(),
      builder: (context, snapshot) {
        int totalSpots = 0;
        int occupiedSpots = 0;
        int availableSpots = 0;
        int reservedSpots = 0;

        if (snapshot.hasData) {
          totalSpots = snapshot.data!.length;
          occupiedSpots = snapshot.data!
              .where((spot) => spot.isOccupied)
              .length;
          availableSpots = snapshot.data!
              .where((spot) => !spot.isOccupied && spot.status != 'reserved')
              .length;
          reservedSpots = snapshot.data!
              .where((spot) => spot.status == 'reserved')
              .length;
        }

        return Card(
          elevation: 4,
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '📈 Statistiques Temps Réel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      '$totalSpots',
                      Icons.local_parking,
                      Colors.blue,
                      isDarkMode,
                    ),
                    _buildStatItem(
                      'Occupées',
                      '$occupiedSpots',
                      Icons.directions_car,
                      Colors.red,
                      isDarkMode,
                    ),
                    _buildStatItem(
                      'Libres',
                      '$availableSpots',
                      Icons.local_parking,
                      Colors.green,
                      isDarkMode,
                    ),
                    _buildStatItem(
                      'Réservées',
                      '$reservedSpots',
                      Icons.event_available,
                      Colors.orange,
                      isDarkMode,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                LinearProgressIndicator(
                  value: totalSpots > 0 ? (occupiedSpots / totalSpots) : 0,
                  backgroundColor: isDarkMode
                      ? Colors.grey[600]
                      : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    totalSpots > 0 && (occupiedSpots / totalSpots) > 0.8
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Taux d\'occupation: ${totalSpots > 0 ? ((occupiedSpots / totalSpots) * 100).toStringAsFixed(1) : 0}%',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildReservationHistory(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 4,
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            elevation: 4,
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 4,
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'Aucune réservation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Les réservations apparaîtront ici',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: [
            // Stats Header
            Card(
              elevation: 2,
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHistoryStatChip(
                      'Total',
                      docs.length.toString(),
                      Colors.blue,
                    ),
                    _buildHistoryStatChip(
                      'Confirmées',
                      _getConfirmedCount(docs).toString(),
                      Colors.green,
                    ),
                    _buildHistoryStatChip(
                      'Aujourd\'hui',
                      _getTodayCount(docs).toString(),
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Table
            Card(
              elevation: 4,
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all(
                      isDarkMode ? Colors.grey[700] : Colors.blue[50],
                    ),
                    dataRowMinHeight: 50,
                    dataRowMaxHeight: 70,
                    columns: [
                      DataColumn(
                        label: Text(
                          'ID Réservation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Place',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Plaque',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Début',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Fin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Statut',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Créée le',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final reservationId = data['reservation_id'] ?? 'N/A';
                      final spotId = data['spot_id'] ?? 'N/A';
                      final licensePlate = data['license_plate'] ?? 'N/A';
                      final email = data['email'] ?? 'N/A';
                      final status = data['status'] ?? 'N/A';

                      final reservationDate = data['reservation_date'] != null
                          ? DateTime.parse(data['reservation_date'])
                          : null;

                      final reservedUntil = data['reserved_until'] != null
                          ? DateTime.parse(data['reserved_until'])
                          : null;

                      final createdAt = data['created_at'] != null
                          ? (data['created_at'] as Timestamp).toDate()
                          : null;

                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                reservationId,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                spotId,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              licensePlate,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(Text(email, style: TextStyle(fontSize: 12))),
                          DataCell(
                            Text(
                              reservationDate != null
                                  ? '${reservationDate.day.toString().padLeft(2, '0')}/${reservationDate.month.toString().padLeft(2, '0')}/${reservationDate.year}'
                                  : 'N/A',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              reservationDate != null
                                  ? '${reservationDate.hour.toString().padLeft(2, '0')}:${reservationDate.minute.toString().padLeft(2, '0')}'
                                  : 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              reservedUntil != null
                                  ? '${reservedUntil.hour.toString().padLeft(2, '0')}:${reservedUntil.minute.toString().padLeft(2, '0')}'
                                  : 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  createdAt != null
                                      ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                                      : 'N/A',
                                  style: TextStyle(fontSize: 11),
                                ),
                                Text(
                                  createdAt != null
                                      ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                                      : '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  int _getTodayCount(List<QueryDocumentSnapshot> docs) {
    final today = DateTime.now();
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['created_at'] == null) return false;
      final createdAt = (data['created_at'] as Timestamp).toDate();
      return createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day;
    }).length;
  }

  int _getConfirmedCount(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'confirmed';
    }).length;
  }
}
