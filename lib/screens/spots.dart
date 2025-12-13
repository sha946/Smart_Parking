import 'package:flutter/material.dart';
import '../firebase_service.dart';
import '../models/parking_spot.dart';

import 'reservation.dart';
import '../models/parking_spot.dart';

class SpotsPage extends StatefulWidget {
  const SpotsPage({super.key});

  @override
  _SpotsPageState createState() => _SpotsPageState();
}

class _SpotsPageState extends State<SpotsPage> {
  final FirebaseService _service = FirebaseService();

  @override
  void initState() {
    super.initState();
    _debugData();
  }

  void _debugData() {
    _service.getParkingSpots().listen(
      (spots) {
        print('=== DEBUG: Parking Spots Data ===');
        print('Number of spots: ${spots.length}');
        for (var spot in spots) {
          print('Spot ${spot.id}:');
          print('  isOccupied: ${spot.isOccupied}');
          print('  status: ${spot.status}');
          print('  entryTime: ${spot.entryTime}');
          print('  licensePlate: ${spot.licensePlate}');
          print('  plaque: ${spot.plaque}');
        }
        print('================================');
      },
      onError: (error) {
        print('Stream error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Places de Parking',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.book_online),
            onPressed: () {
              _navigateToReservationPage();
            },
            tooltip: 'Réserver une place',
          ),

          // Bouton pour naviguer vers la page Maps
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: StreamBuilder<List<ParkingSpot>>(
        stream: _service.getParkingSpots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error in stream: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de connexion: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Aucune donnée disponible'));
          }

          final spots = snapshot.data ?? [];

          if (spots.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_parking, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune place de parking disponible',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Sort spots by ID for better organization
          spots.sort((a, b) => a.id.compareTo(b.id));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final spot = spots[index];
              return _buildSpotCard(spot);
            },
          );
        },
      ),
    );
  }

  Widget _buildSpotCard(ParkingSpot spot) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    // Determine status based on available data
    // First check explicit status, then fall back to isOccupied
    if (spot.status == 'reserved') {
      statusColor = Colors.orange;
      statusIcon = Icons.event;
      statusText = 'Réservé';
    } else if (spot.status == 'occupied' || spot.isOccupied) {
      statusColor = Colors.red;
      statusIcon = Icons.block;
      statusText = 'Occupé';
    } else if (spot.status == 'free') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Libre';
    } else {
      // Default to free if no status and not occupied
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Libre';
    }

    // Format the entryTime for display
    String? formattedEntryTime;
    if (spot.entryTime != null) {
      try {
        final dateTime = DateTime.parse(spot.entryTime!);
        formattedEntryTime =
            '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedEntryTime = spot.entryTime; // Use raw string if parsing fails
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 28),
        ),
        title: Text(
          'Place ${spot.id}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (spot.licensePlate != null && spot.licensePlate!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Plaque: ${spot.licensePlate}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
            if (spot.plaque != null &&
                spot.plaque!.isNotEmpty &&
                spot.plaque != spot.licensePlate) ...[
              const SizedBox(height: 4),
              Text(
                'Plaque (alt): ${spot.plaque}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
            if (spot.entryTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Entrée: ${formattedEntryTime ?? spot.entryTime}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          _showSpotDetails(spot);
        },
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';

    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return dateTimeString; // Return original if parsing fails
    }
  }

  void _showSpotDetails(ParkingSpot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - Place ${spot.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', spot.id),
              _buildDetailRow(
                'Statut',
                spot.status.isNotEmpty
                    ? spot.status
                    : (spot.isOccupied ? 'occupied' : 'free'),
              ),
              _buildDetailRow('Occupé', spot.isOccupied ? 'Oui' : 'Non'),
              if (spot.licensePlate != null && spot.licensePlate!.isNotEmpty)
                _buildDetailRow('Plaque', spot.licensePlate!),
              if (spot.plaque != null && spot.plaque!.isNotEmpty)
                _buildDetailRow('Plaque (alternatif)', spot.plaque!),
              if (spot.entryTime != null)
                _buildDetailRow(
                  'Heure d\'entrée',
                  _formatDateTime(spot.entryTime),
                ),
              if (spot.exitTime != null)
                _buildDetailRow(
                  'Heure de sortie',
                  _formatDateTime(spot.exitTime),
                ),
              if (spot.reservationStart != null)
                _buildDetailRow(
                  'Début réservation',
                  _formatDateTime(spot.reservationStart),
                ),
              if (spot.reservationEnd != null)
                _buildDetailRow(
                  'Fin réservation',
                  _formatDateTime(spot.reservationEnd),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Méthode pour naviguer vers la page Maps

  void _navigateToReservationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReservationPage()),
    );
  }
}
