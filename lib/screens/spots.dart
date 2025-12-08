import 'package:flutter/material.dart';
import '../firebase_service.dart';
import '../models/parking_spot.dart';
import 'maps_page.dart'; // Importez votre fichier maps.dart

class SpotsPage extends StatefulWidget {
  const SpotsPage({super.key});

  @override
  _SpotsPageState createState() => _SpotsPageState();
}

class _SpotsPageState extends State<SpotsPage> {
  final FirebaseService _service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Places de Parking',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Bouton pour naviguer vers la page Maps
          IconButton(
            icon: const Icon(Icons.video_camera_front),
            onPressed: () {
              _navigateToMapsPage();
            },
            tooltip: 'Voir le flux vidéo',
          ),
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
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final spots = snapshot.data ?? [];

          if (spots.isEmpty) {
            return const Center(
              child: Text('Aucune place de parking disponible'),
            );
          }

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

    if (spot.status == 'reserved') {
      statusColor = Colors.orange;
      statusIcon = Icons.event;
      statusText = 'Réservé';
    } else if (spot.isOccupied) {
      statusColor = Colors.red;
      statusIcon = Icons.block;
      statusText = 'Occupé';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Libre';
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
            if (spot.licensePlate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Plaque: ${spot.licensePlate}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
            if (spot.entryTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Entrée: ${spot.entryTime}',
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

  void _showSpotDetails(ParkingSpot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - Place ${spot.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Statut', spot.status),
            _buildDetailRow('Occupé', spot.isOccupied ? 'Oui' : 'Non'),
            if (spot.licensePlate != null)
              _buildDetailRow('Plaque', spot.licensePlate!),
            if (spot.entryTime != null)
              _buildDetailRow('Heure d\'entrée', spot.entryTime!),
            if (spot.exitTime != null)
              _buildDetailRow('Heure de sortie', spot.exitTime!),
            if (spot.reservationStart != null)
              _buildDetailRow('Début réservation', spot.reservationStart!),
            if (spot.reservationEnd != null)
              _buildDetailRow('Fin réservation', spot.reservationEnd!),
          ],
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
  void _navigateToMapsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapsPage()),
    );
  }
}
