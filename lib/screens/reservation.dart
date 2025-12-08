import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  String? _selectedSpot;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedDuration = 1; // Durée en heures
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _saveCardInfo = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Tarifs simplifiés pour test
  final Map<int, double> _durationRates = {
    1: 2.0, // 2€ pour 1 heure
    2: 3.5, // 3.5€ pour 2 heures
    3: 5.0, // 5€ pour 3 heures
  };

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }

    if (widget.preSelectedSpot != null) {
      _selectedSpot = widget.preSelectedSpot;
    }

    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  double get _calculatedPrice {
    return _durationRates[_selectedDuration] ?? 2.0;
  }

  DateTime get _endTime {
    if (_selectedDate == null || _selectedTime == null) return DateTime.now();

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    return startDateTime.add(Duration(hours: _selectedDuration));
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildInfoHeader(availableSpots.length),
                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView(
                      children: [
                        _buildEmailField(),
                        const SizedBox(height: 16),
                        _buildLicensePlateField(),
                        const SizedBox(height: 16),
                        _buildDateTimeSelection(),
                        const SizedBox(height: 16),
                        _buildDurationSelection(),
                        const SizedBox(height: 16),

                        // SECTION SÉLECTION DES PLACES AVEC ICÔNES
                        _buildSpotSelection(availableSpots),
                        const SizedBox(height: 20),

                        // Section Paiement
                        _buildPaymentSection(),
                        const SizedBox(height: 16),

                        _buildPricingSection(),
                        const SizedBox(height: 16),
                        _buildTermsAndConditions(),
                        const SizedBox(height: 30),
                        _buildReservationButton(availableSpots.isNotEmpty),
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

  // Section Paiement
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

            // Numéro de carte
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
                // Formatage automatique
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
                // Date d'expiration
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
                // CVV
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

            // Titulaire de la carte
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

            // Option pour sauvegarder la carte
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
        child: Row(
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
                  const SizedBox(height: 4),
                  if (widget.preSelectedSpot != null)
                    Text(
                      'Place présélectionnée: ${widget.preSelectedSpot}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (availableSpots > 0)
                    const Text(
                      'Sélectionnez une place et complétez les informations',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    )
                  else
                    const Text(
                      'Aucune place disponible pour le moment',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email *',
        hintText: 'votre@email.com',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty)
          return 'Veuillez entrer votre email';
        return null;
      },
    );
  }

  Widget _buildLicensePlateField() {
    return TextFormField(
      controller: _licensePlateController,
      decoration: const InputDecoration(
        labelText: 'Plaque d\'immatriculation *',
        hintText: 'AB-123-CD',
        prefixIcon: Icon(Icons.confirmation_number),
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Veuillez entrer la plaque';
        return null;
      },
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
        if (_selectedDate != null && _selectedTime != null) ...[
          const SizedBox(height: 8),
          Text(
            'Fin: ${_endTime.hour}h${_endTime.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ],
      ],
    );
  }

  // SECTION SÉLECTION DES PLACES AVEC PETITES ICÔNES
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

  // GRILLE COMPACTE DES PLACES AVEC PETITES ICÔNES
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
          crossAxisCount: 6, // Plus de colonnes pour des icônes plus petites
          childAspectRatio: 0.9, // Ratio carré
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: spots.length,
        itemBuilder: (context, index) {
          final spot = spots[index];
          final isSelected = _selectedSpot == spot.id;
          final isPreSelected = widget.preSelectedSpot == spot.id;

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
                    size: 20, // Icône petite
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

  Widget _buildReservationButton(bool hasAvailableSpots) {
    final isFormValid =
        _agreeToTerms &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedSpot != null &&
        _cardNumberController.text.isNotEmpty &&
        _expiryDateController.text.isNotEmpty &&
        _cvvController.text.isNotEmpty &&
        _cardHolderController.text.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: hasAvailableSpots && !_isLoading && isFormValid
            ? _makeReservation
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

  Future<void> _makeReservation() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorDialog('Veuillez corriger les erreurs dans le formulaire');
      return;
    }

    if (!_agreeToTerms) {
      _showErrorDialog('Veuillez accepter les conditions générales');
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

      // Simuler le traitement du paiement
      await _processPayment();

      // Réservation avec la date de création actuelle
      await _service.reserveSpot(
        spotId: _selectedSpot!,
        
        licensePlate: _licensePlateController.text.trim(),
        email: _emailController.text.trim(),
        reservationDate: _selectedDate!,
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        duration: _selectedDuration,
        price: _calculatedPrice,
      );

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Simulation du traitement de paiement
  Future<void> _processPayment() async {
    // Simuler un délai de traitement
    await Future.delayed(const Duration(seconds: 2));

    // Dans une application réelle, vous intégreriez ici une API de paiement
    // comme Stripe, PayPal, etc.

    // Pour le moment, on simule juste un paiement réussi
    return;
  }

  void _showSuccessDialog() {
    final creationDate = DateTime.now(); // Date actuelle pour la création

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
            Text('⏱️ Durée: $_selectedDuration heure(s)'),
            Text('💰 Prix: ${_calculatedPrice.toStringAsFixed(2)}dt'),
            Text('📅 Date de réservation: ${_formatDate(creationDate)}'),
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

  // Fonction pour formater la date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Méthode pour afficher les erreurs (ajoutée car manquante)
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _licensePlateController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }
}
