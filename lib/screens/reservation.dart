import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; // Ajouté pour Realtime Database
import '../models/parking_spot.dart';
import '../firebase_service.dart';

class ReservationPage extends StatefulWidget {
  final String? preSelectedSpot;

  const ReservationPage({super.key, this.preSelectedSpot});

  @override
  _ReservationPageState createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final FirebaseService _service = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance
      .ref(); // Pour Realtime Database

  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  String? _selectedSpot;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedDuration = 1;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _saveCardInfo = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Tarifs
  final Map<int, double> _durationRates = {1: 2.0, 2: 3.5, 3: 5.0};

  // Liste des emails autorisés
  final List<String> _authorizedEmails = [
    'najet@gmail.com',
    'abc@gmail.com',
    'aa@gmail.com',
    'chaima@gmail.com',
  ];

  // Liste des plaques d'immatriculation autorisées
  final List<String> _authorizedLicensePlates = ['123ABC', '456DEF', '789GHI'];

  bool _isEmailAuthorized = false;
  bool _isLicensePlateValid = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();

    // Vérifier si l'email est autorisé
    _checkEmailAuthorization();
  }

  void _checkEmailAuthorization() {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      final userEmail = user.email!.toUpperCase().trim();
      setState(() {
        _isEmailAuthorized = _authorizedEmails.any(
          (email) => email.toUpperCase().trim() == userEmail,
        );
      });
    }
  }

  bool _checkLicensePlateAuthorization(String plate) {
    final normalizedPlate = plate.toUpperCase().trim();
    return _authorizedLicensePlates.any(
      (authPlate) => authPlate.toUpperCase().trim() == normalizedPlate,
    );
  }

  double get _calculatedPrice {
    return _durationRates[_selectedDuration] ?? 2.0;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    // Vérifier si l'utilisateur est authentifié
    if (user == null) {
      return _buildUnauthenticatedView();
    }

    // Vérifier si l'email est autorisé
    if (!_isEmailAuthorized) {
      return _buildUnauthorizedEmailView(user.email);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Réserver une Place',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ParkingSpot>>(
        stream: _service.getParkingSpots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildNoDataView();
          }

          final spots = snapshot.data!;
          final availableSpots = spots
              .where((spot) => !spot.isOccupied && spot.status != 'reserved')
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfoHeader(user),
                  const SizedBox(height: 10),
                  _buildInfoHeader(availableSpots.length),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView(
                      children: [
                        _buildLicensePlateField(),
                        const SizedBox(height: 16),
                        _buildDateTimeSelection(),
                        const SizedBox(height: 16),
                        _buildDurationSelection(),
                        const SizedBox(height: 16),

                        _buildSpotSelection(availableSpots),
                        const SizedBox(height: 20),

                        _buildPaymentSection(),
                        const SizedBox(height: 16),

                        _buildPricingSection(),
                        const SizedBox(height: 16),
                        _buildTermsAndConditions(),
                        const SizedBox(height: 30),
                        _buildReservationButton(
                          availableSpots.isNotEmpty,
                          user,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservation'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Authentification requise',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Veuillez vous connecter pour réserver une place',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthorizedEmailView(String? userEmail) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservation'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Email non autorisé',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Votre email n\'est pas autorisé à effectuer des réservations',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Votre email:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userEmail ?? 'Non disponible',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Emails autorisés:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ..._authorizedEmails
                      .map(
                        (email) => Text(email, style: TextStyle(fontSize: 12)),
                      )
                      .toList(),
                ],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader(User user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.person, color: Colors.green.shade800),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Utilisateur autorisé',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    user.email ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
            Icon(Icons.verified, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLicensePlateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plaque d\'immatriculation *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _licensePlateController,
          decoration: InputDecoration(
            labelText: 'Plaque d\'immatriculation',
            hintText: '123ABC',
            prefixIcon: Icon(Icons.confirmation_number),
            border: OutlineInputBorder(),
            suffixIcon: _licensePlateController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      _isLicensePlateValid ? Icons.check_circle : Icons.warning,
                      color: _isLicensePlateValid
                          ? Colors.green
                          : Colors.orange,
                    ),
                    onPressed: _verifyLicensePlate,
                  )
                : null,
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            setState(() {
              _isLicensePlateValid = false;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer la plaque d\'immatriculation';
            }
            if (!_isLicensePlateValid) {
              return 'Veuillez vérifier que cette plaque est autorisée';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _verifyLicensePlate,
                icon: Icon(Icons.verified_user, size: 18),
                label: Text('Vérifier cette plaque'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: _showAuthorizedPlates,
              icon: Icon(Icons.info_outline, color: Colors.blue),
              tooltip: 'Voir les plaques autorisées',
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _verifyLicensePlate() async {
    final plate = _licensePlateController.text.trim();

    if (plate.isEmpty) {
      _showErrorDialog(
        'Plaque vide',
        'Veuillez entrer une plaque d\'immatriculation',
      );
      return;
    }

    final isValid = _checkLicensePlateAuthorization(plate);

    setState(() {
      _isLicensePlateValid = isValid;
    });

    if (isValid) {
      _showPlateVerificationDialog(
        'Plaque autorisée',
        'Cette plaque est autorisée pour la réservation',
      );
    } else {
      _showErrorDialog(
        'Plaque non autorisée',
        'Cette plaque n\'est pas dans la liste des plaques autorisées',
      );
    }
  }

  void _showAuthorizedPlates() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.directions_car, color: Colors.blue),
            SizedBox(width: 8),
            Text('Plaques autorisées'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seules ces plaques sont autorisées:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ..._authorizedLicensePlates
                .map(
                  (plate) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text(plate, style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                )
                .toList(),
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

  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date et heure de début *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'Non sélectionnée'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _selectDate,
                            icon: Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Heure',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedTime == null
                                  ? 'Non sélectionnée'
                                  : '${_selectedTime!.hour}h${_selectedTime!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedTime == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _selectTime,
                            icon: Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Durée de stationnement *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _durationRates.entries.map((entry) {
            final duration = entry.key;
            final price = entry.value;
            final isSelected = _selectedDuration == duration;

            return ChoiceChip(
              label: Text('$duration h - ${price.toStringAsFixed(2)}dt'),
              selected: isSelected,
              onSelected: (selected) =>
                  setState(() => _selectedDuration = duration),
              selectedColor: Colors.blue.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade800 : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpotSelection(List<ParkingSpot> availableSpots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez une place *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        availableSpots.isEmpty
            ? _buildNoSpotsAvailable()
            : _buildCompactSpotsGrid(availableSpots),
      ],
    );
  }

  Widget _buildNoSpotsAvailable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.local_parking, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          const Text(
            'Aucune place disponible pour le moment',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSpotsGrid(List<ParkingSpot> spots) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 0.9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: spots.length,
        itemBuilder: (context, index) {
          final spot = spots[index];
          final isSelected = _selectedSpot == spot.id;

          return GestureDetector(
            onTap: () => setState(() => _selectedSpot = spot.id),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.shade800
                      : Colors.grey.shade400,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_parking,
                    color: isSelected ? Colors.white : Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spot.id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.credit_card, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Informations de Paiement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de carte *',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le numéro de carte';
                }
                if (value.replaceAll(' ', '').length != 16) {
                  return 'Le numéro de carte doit contenir 16 chiffres';
                }
                return null;
              },
              onChanged: (value) {
                if (value.length == 4 ||
                    value.length == 9 ||
                    value.length == 14) {
                  _cardNumberController.text = '$value ';
                  _cardNumberController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _cardNumberController.text.length),
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryDateController,
                    decoration: const InputDecoration(
                      labelText: 'MM/AA *',
                      hintText: '12/25',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer la date d\'expiration';
                      }
                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                        return 'Format invalide (MM/AA)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV *',
                      hintText: '123',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le CVV';
                      }
                      if (value.length != 3) {
                        return 'Le CVV doit contenir 3 chiffres';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _cardHolderController,
              decoration: const InputDecoration(
                labelText: 'Titulaire de la carte *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nom du titulaire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Checkbox(
                  value: _saveCardInfo,
                  onChanged: (value) =>
                      setState(() => _saveCardInfo = value ?? false),
                ),
                const Text('Sauvegarder les informations de carte'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails du prix',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Durée:'),
                Text('$_selectedDuration heure(s)'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tarif:'),
                Text(
                  '${_durationRates[_selectedDuration]?.toStringAsFixed(2)}dt',
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_calculatedPrice.toStringAsFixed(2)}dt',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
        ),
        const Expanded(
          child: Text(
            'J\'accepte les conditions générales',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationButton(bool hasAvailableSpots, User user) {
    final isFormValid =
        _agreeToTerms &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedSpot != null &&
        _licensePlateController.text.isNotEmpty &&
        _isLicensePlateValid &&
        _cardNumberController.text.isNotEmpty &&
        _expiryDateController.text.isNotEmpty &&
        _cvvController.text.isNotEmpty &&
        _cardHolderController.text.isNotEmpty &&
        _isEmailAuthorized;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: hasAvailableSpots && !_isLoading && isFormValid
            ? () => _makeReservation(user)
            : null,
        icon: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.book_online),
        label: Text(
          _isLoading ? 'Réservation en cours...' : 'Confirmer la réservation',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasAvailableSpots && isFormValid
              ? Colors.blue.shade800
              : Colors.grey,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _makeReservation(User user) async {
    if (!_formKey.currentState!.validate()) {
      _showErrorDialog('Veuillez corriger les erreurs dans le formulaire');
      return;
    }

    if (!_agreeToTerms) {
      _showErrorDialog('Veuillez accepter les conditions générales');
      return;
    }

    // Double-check email authorization
    if (!_isEmailAuthorized) {
      _showErrorDialog(
        'Email non autorisé',
        'Votre email n\'est pas autorisé à effectuer des réservations',
      );
      return;
    }

    // Double-check license plate authorization
    final isLicensePlateValid = _checkLicensePlateAuthorization(
      _licensePlateController.text.trim(),
    );

    if (!isLicensePlateValid) {
      _showErrorDialog(
        'Plaque non autorisée',
        'Cette plaque n\'est pas autorisée pour la réservation',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isAvailable = await _service.isSpotAvailable(_selectedSpot!);
      if (!isAvailable) {
        _showErrorDialog('Cette place n\'est plus disponible');
        setState(() => _isLoading = false);
        return;
      }

      // Simuler le paiement
      await _processPayment();

      // Créer la réservation dans Firestore et mettre à jour Realtime Database
      await _createReservationInFirestore(user);

      _showReservationSuccessDialog();
    } catch (e) {
      String errorMessage = 'Erreur lors de la réservation';
      if (e.toString().contains('No document to update')) {
        errorMessage = 'Problème avec la base de données. Veuillez réessayer.';
      } else if (e.toString().contains('parking_spots')) {
        errorMessage = 'Problème d\'accès à la base de données des places.';
      }

      _showErrorDialog('Erreur', '$errorMessage\n\nDétails: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createReservationInFirestore(User user) async {
    try {
      // Créer DateTime pour reservationDateTime
      final reservationDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // 1. CRÉER LA RÉSERVATION DANS FIRESTORE
      final reservationRef = await _firestore.collection('reservations').add({
        'spotId': _selectedSpot!,
        'licensePlate': _licensePlateController.text.trim().toUpperCase(),
        'email': user.email!,
        'duration': _selectedDuration,
        'price': _calculatedPrice,
        'reservationDateTime': Timestamp.fromDate(reservationDateTime),
        'creationDate': Timestamp.now(),
        'status': 'confirmed',
      });

      print("✅ Réservation créée dans Firestore avec ID: ${reservationRef.id}");

      // 2. METTRE À JOUR LA PLACE DANS REALTIME DATABASE
      try {
        // Vérifier d'abord si la place existe
        final spotSnapshot = await _database
            .child('parking_spots')
            .child(_selectedSpot!)
            .get();

        if (spotSnapshot.exists) {
          // Mettre à jour la place existante
          await _database.child('parking_spots').child(_selectedSpot!).update({
            'isOccupied': true,
            'status': 'reserved',
            'lastUpdated': ServerValue.timestamp,
          });
          print("✅ Place $_selectedSpot mise à jour dans Realtime Database");
        } else {
          // Créer la place si elle n'existe pas
          await _database.child('parking_spots').child(_selectedSpot!).set({
            'id': _selectedSpot!,
            'isOccupied': true,
            'status': 'reserved',
            'createdAt': ServerValue.timestamp,
            'lastUpdated': ServerValue.timestamp,
          });
          print("✅ Place $_selectedSpot créée dans Realtime Database");
        }
      } catch (e) {
        print(
          "⚠️ Erreur lors de la mise à jour de la place dans Realtime Database: $e",
        );
        // On peut continuer même si la mise à jour de la place échoue
        // La réservation est déjà créée dans Firestore
      }
    } catch (e) {
      print("❌ Erreur lors de la création de la réservation: $e");
      rethrow;
    }
  }

  Future<void> _processPayment() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  void _showReservationSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Réservation Confirmée'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Place: $_selectedSpot'),
            Text('🚗 Plaque: ${_licensePlateController.text}'),
            Text('📧 Email: ${_auth.currentUser?.email}'),
            Text('⏱️ Durée: $_selectedDuration heure(s)'),
            Text('💰 Prix: ${_calculatedPrice.toStringAsFixed(2)}dt'),
            const SizedBox(height: 16),
            const Text(
              'Votre réservation a été confirmée!',
              style: TextStyle(fontSize: 14, color: Colors.green),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paiement effectué avec succès',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPlateVerificationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, [String? message]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message ?? title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Aucune donnée de parking disponible',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoHeader(int availableSpots) {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$availableSpots place(s) disponible(s)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Email autorisé: ${_auth.currentUser?.email}',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _isLicensePlateValid ? Icons.check_circle : Icons.warning,
                  size: 16,
                  color: _isLicensePlateValid ? Colors.green : Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  _isLicensePlateValid
                      ? 'Plaque autorisée: ${_licensePlateController.text}'
                      : 'Vérifiez votre plaque d\'immatriculation',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isLicensePlateValid ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }
}
