import 'package:flutter/material.dart';
import '../firebase_service.dart';
import '../models/parking_spot.dart';
import 'reservation.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final FirebaseService _service = FirebaseService();
  final String _raspberryVideoUrl = "http://[ADRESSE_IP_RASPBERRY]:8000/stream";

  String? _selectedFreeSpot; // Pour stocker la place libre sélectionnée

  Color _getStatusColor(ParkingSpot spot) {
    if (spot.isOccupied) {
      return Colors.red[300]!;
    } else if (spot.status == 'reserved') {
      return Colors.orange[300]!;
    } else {
      return Colors.green[300]!;
    }
  }

  Color _getStatusColorForRow(ParkingSpot spot) {
    if (spot.isOccupied) {
      return Colors.red;
    } else if (spot.status == 'reserved') {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  IconData _getSpotIcon(ParkingSpot spot) {
    if (spot.isOccupied) {
      return Icons.directions_car;
    } else if (spot.status == 'reserved') {
      return Icons.event_available;
    } else {
      return Icons.check;
    }
  }

  String _getStatusText(ParkingSpot spot) {
    if (spot.isOccupied) {
      return 'Occupée';
    } else if (spot.status == 'reserved') {
      return 'Réservée';
    } else {
      return 'Libre';
    }
  }

  // Fonction pour séparer les spots par section (A et B)
  Map<String, List<ParkingSpot>> _groupSpotsBySection(List<ParkingSpot> spots) {
    final sectionA = spots.where((spot) => spot.id.startsWith('A')).toList();
    final sectionB = spots.where((spot) => spot.id.startsWith('B')).toList();

    // Trier par ordre numérique
    sectionA.sort((a, b) => a.id.compareTo(b.id));
    sectionB.sort((a, b) => a.id.compareTo(b.id));

    return {'Section A': sectionA, 'Section B': sectionB};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map du parking',
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ParkingSpot>>(
        stream: _service.getParkingSpots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildVideoSection();
          }

          final spots = snapshot.data!;
          final freeSpots = spots
              .where((s) => !s.isOccupied && s.status != 'reserved')
              .toList();

          final groupedSpots = _groupSpotsBySection(spots);

          return Column(
            children: [
              // Section Vidéo Raspberry
              _buildVideoSection(),

              // Header avec info
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${freeSpots.length} place(s) libre(s) disponible(s)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Légende
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(Colors.green, 'Libre'),
                    const SizedBox(width: 20),
                    _buildLegend(Colors.red, 'Occupé'),
                    const SizedBox(width: 20),
                    _buildLegend(Colors.orange, 'Réservé'),
                  ],
                ),
              ),

              // Plan du parking (vue de dessus)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildParkingSection(
                        'Section A',
                        groupedSpots['Section A']!,
                      ),
                      const SizedBox(height: 30),
                      _buildParkingSection(
                        'Section B',
                        groupedSpots['Section B']!,
                      ),
                      const SizedBox(height: 30),

                      // SECTION CHOISIR UNE PLACE LIBRE - EN BAS
                      _buildFreeSpotsSection(freeSpots),
                    ],
                  ),
                ),
              ),

              // Bouton de navigation
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedFreeSpot != null
                        ? () {
                            final spot = spots.firstWhere(
                              (s) => s.id == _selectedFreeSpot,
                            );
                            _navigateToFreeSpot(spot);
                          }
                        : freeSpots.isNotEmpty
                        ? () {
                            // Sélectionner la première place libre par défaut
                            setState(() {
                              _selectedFreeSpot = freeSpots.first.id;
                            });
                            _navigateToFreeSpot(freeSpots.first);
                          }
                        : null,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Naviguer vers place libre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // NOUVELLE SECTION POUR LES PLACES LIBRES - MÊME FORME QUE SECTIONS A ET B
  Widget _buildFreeSpotsSection(List<ParkingSpot> freeSpots) {
    if (freeSpots.isEmpty) {
      return Container(); // Retourne un container vide si pas de places libres
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir une place libre',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: freeSpots.length,
          itemBuilder: (context, index) {
            final spot = freeSpots[index];
            final isSelected = _selectedFreeSpot == spot.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFreeSpot = spot.id;
                });
                _showSpotInfo(spot);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[300] : Colors.green[300],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.green,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? Icons.navigation : Icons.local_parking,
                      color: Colors.white,
                      size: 20,
                    ),
                    Text(
                      spot.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (isSelected)
                      const Text(
                        'Sélectionnée',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Image.network(
      _raspberryVideoUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 50, color: Colors.grey),
              const SizedBox(height: 10),
              const Text(
                'Flux vidéo non disponible',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                'URL: $_raspberryVideoUrl',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildParkingSection(String title, List<ParkingSpot> spots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: spots.length,
          itemBuilder: (context, index) {
            final spot = spots[index];
            return GestureDetector(
              onTap: () => _showSpotInfo(spot),
              child: Container(
                decoration: BoxDecoration(
                  color: _getStatusColor(spot),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getSpotIcon(spot), color: Colors.white, size: 20),
                    Text(
                      spot.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSpotInfo(ParkingSpot spot) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Place ${spot.id}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.circle,
              'État',
              _getStatusText(spot),
              _getStatusColorForRow(spot),
            ),
            if (spot.licensePlate != null)
              _buildInfoRow(
                Icons.confirmation_number,
                'Plaque',
                spot.licensePlate!,
                Colors.blue,
              ),
            if (spot.entryTime != null)
              _buildInfoRow(
                Icons.access_time,
                'Entrée',
                _formatTime(spot.entryTime!),
                Colors.orange,
              ),
            if (spot.exitTime != null)
              _buildInfoRow(
                Icons.exit_to_app,
                'Sortie',
                _formatTime(spot.exitTime!),
                Colors.purple,
              ),
            const SizedBox(height: 20),
            if (!spot.isOccupied && spot.status != 'reserved')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedFreeSpot = spot.id;
                        });
                        _navigateToFreeSpot(spot);
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Y aller'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToReservationPageWithSpot(spot.id);
                      },
                      icon: const Icon(Icons.book_online),
                      label: const Text('Réserver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            if (spot.status == 'reserved')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Réservée'),
                ),
              ),
            if (spot.isOccupied && spot.status != 'reserved')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Occupée'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _navigateToFreeSpot(ParkingSpot spot) {
    // Faire défiler vers la section des places libres
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = this.context;
      final renderObject = context.findRenderObject();
      if (renderObject != null) {
        renderObject.showOnScreen();
      }
    });
  }

  void _navigateToReservationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReservationPage()),
    );
  }

  void _navigateToReservationPageWithSpot(String spotId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationPage(preSelectedSpot: spotId),
      ),
    );
  }
}
