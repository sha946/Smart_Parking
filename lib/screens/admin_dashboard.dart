import 'package:flutter/material.dart';
import '../firebase_service.dart';
import '../models/parking_spot.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme_manager.dart';

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
            SizedBox(height: 20),

            // TABLEAU DES PLACES
            Text(
              '📊 État des Places de Parking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            _buildParkingTable(context),
            SizedBox(height: 20),

            // ALERTES
            Text(
              '🚨 Alertes de Paiement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            _buildAlertsSection(isDarkMode),
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
          // CORRECTION : Les places réservées ne sont pas disponibles
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
                  // CORRECTION : Calcul correct du taux d'occupation
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

  Widget _buildParkingTable(BuildContext context) {
    return StreamBuilder<List<ParkingSpot>>(
      stream: _service.getParkingSpots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final spots = snapshot.data!;

        return Card(
          elevation: 4,
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Détail des Places',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${spots.length} places',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 60,
                    columns: [
                      DataColumn(
                        label: Text(
                          'Place',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Statut',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Plaque',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Entrée',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Sortie',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Réservation',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: spots.map((spot) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              spot.id,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(spot),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(spot),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              spot.licensePlate ?? '---',
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          DataCell(Text(_formatDateTime(spot.entryTime))),
                          DataCell(Text(_formatDateTime(spot.exitTime))),
                          DataCell(
                            Text(
                              _getReservationInfo(spot),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getReservationColor(spot),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.info, size: 18),
                                  onPressed: () =>
                                      _showSpotDetails(context, spot),
                                  tooltip: 'Détails',
                                ),
                                if (spot.isOccupied ||
                                    spot.status == 'reserved')
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _freeSpot(context, spot),
                                    tooltip: 'Libérer la place',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // CORRECTION : Utiliser les propriétés de ParkingSpot pour déterminer le statut
  Color _getStatusColor(ParkingSpot spot) {
    if (spot.isOccupied) {
      return Colors.red;
    } else if (spot.status == 'reserved') {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText(ParkingSpot spot) {
    if (spot.isOccupied) {
      return 'OCCUPÉ';
    } else if (spot.status == 'reserved') {
      return 'RÉSERVÉ';
    } else {
      return 'LIBRE';
    }
  }

  String _getReservationInfo(ParkingSpot spot) {
    if (spot.status == 'reserved') {
      if (spot.reservationStart != null && spot.reservationEnd != null) {
        return '${_formatTime(spot.reservationStart!)}-${_formatTime(spot.reservationEnd!)}';
      }
      return 'Réservée';
    }
    return '---';
  }

  Color _getReservationColor(ParkingSpot spot) {
    if (spot.status == 'reserved') {
      return Colors.orange;
    }
    return Colors.grey;
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '---';

    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '---';
    }
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  Widget _buildAlertsSection(bool isDarkMode) {
    return StreamBuilder<List<ParkingSpot>>(
      stream: _service.getParkingSpots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildAlertsLoading();
        }

        final spots = snapshot.data!;
        final alerts = _generateAlerts(spots);

        return Card(
          elevation: 4,
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Alertes en Cours',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: alerts.isNotEmpty ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alerts.length.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (alerts.isEmpty)
                  _buildNoAlerts(isDarkMode)
                else
                  ...alerts.map(
                    (alert) => _buildAlertItem(
                      spot: alert['spot']!,
                      licensePlate: alert['licensePlate']!,
                      duration: alert['duration']!,
                      type: alert['type']!,
                      time: alert['time']!,
                      isDarkMode: isDarkMode,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsLoading() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildNoAlerts(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 48, color: Colors.green),
          SizedBox(height: 8),
          Text(
            'Aucune alerte pour le moment',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _generateAlerts(List<ParkingSpot> spots) {
    final alerts = <Map<String, String>>[];
    final now = DateTime.now();

    // Vérifier les réservations expirées
    for (final spot in spots) {
      if (spot.status == 'reserved' && spot.reservationEnd != null) {
        try {
          final reservationEnd = DateTime.parse(spot.reservationEnd!);
          if (reservationEnd.isBefore(now)) {
            alerts.add({
              'spot': spot.id,
              'licensePlate': spot.licensePlate ?? 'Inconnue',
              'duration': 'Réservation expirée',
              'type': 'reservation_expired',
              'time': 'Depuis ${now.difference(reservationEnd).inMinutes} min',
            });
          }
        } catch (e) {
          // Ignorer les erreurs de parsing
        }
      }

      // Vérifier les stationnements longs
      if (spot.isOccupied && spot.entryTime != null) {
        try {
          final entryTime = DateTime.parse(spot.entryTime!);
          final duration = now.difference(entryTime);
          if (duration.inHours > 3) {
            // Alerte après 3 heures
            alerts.add({
              'spot': spot.id,
              'licensePlate': spot.licensePlate ?? 'Inconnue',
              'duration':
                  '${duration.inHours}h ${duration.inMinutes.remainder(60)}min',
              'type': 'overtime',
              'time': 'Stationnement long',
            });
          }
        } catch (e) {
          // Ignorer les erreurs de parsing
        }
      }
    }

    return alerts;
  }

  Widget _buildAlertItem({
    required String spot,
    required String licensePlate,
    required String duration,
    required String type,
    required String time,
    required bool isDarkMode,
  }) {
    Color alertColor = Colors.orange;
    IconData alertIcon = Icons.warning;
    String alertText = 'Alerte';

    switch (type) {
      case 'reservation_expired':
        alertColor = Colors.red;
        alertIcon = Icons.timer_off;
        alertText = 'Réservation expirée';
        break;
      case 'overtime':
        alertColor = Colors.orange;
        alertIcon = Icons.timer;
        alertText = 'Stationnement long';
        break;
      default:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        alertText = 'Alerte';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: alertColor,
              shape: BoxShape.circle,
            ),
            child: Icon(alertIcon, color: Colors.white, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Place $spot • $licensePlate • $duration',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => _resolveAlert(spot),
                style: ElevatedButton.styleFrom(
                  backgroundColor: alertColor,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: Text(
                  'Résoudre',
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSpotDetails(BuildContext context, ParkingSpot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails Place ${spot.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Statut:', _getStatusText(spot)),
              _buildDetailItem(
                'Plaque:',
                spot.licensePlate ?? 'Non renseignée',
              ),
              _buildDetailItem(
                'Heure entrée:',
                _formatDateTime(spot.entryTime),
              ),
              _buildDetailItem('Heure sortie:', _formatDateTime(spot.exitTime)),
              if (spot.status == 'reserved') ...[
                _buildDetailItem(
                  'Début réservation:',
                  _formatDateTime(spot.reservationStart),
                ),
                _buildDetailItem(
                  'Fin réservation:',
                  _formatDateTime(spot.reservationEnd),
                ),
              ],
              _buildDetailItem(
                'Durée stationnement:',
                _calculateDuration(spot),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          if (spot.isOccupied || spot.status == 'reserved')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _freeSpot(context, spot);
              },
              child: Text('Libérer', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _calculateDuration(ParkingSpot spot) {
    if (spot.entryTime == null) return '---';

    try {
      final entry = DateTime.parse(spot.entryTime!);
      final now = DateTime.now();
      final difference = now.difference(entry);

      if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes.remainder(60)}min';
      } else {
        return '${difference.inMinutes}min';
      }
    } catch (e) {
      return '---';
    }
  }

  void _freeSpot(BuildContext context, ParkingSpot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Libérer la place'),
        content: Text('Êtes-vous sûr de vouloir libérer la place ${spot.id} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.freeSpot(spot.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Place ${spot.id} libérée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la libération: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Libérer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resolveAlert(String spotId) {
    // Implémentation pour résoudre une alerte
    // Cette méthode pourrait libérer la place ou marquer l'alerte comme résolue
    print('Résolution de l\'alerte pour la place $spotId');
  }
}
