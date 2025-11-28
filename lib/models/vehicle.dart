class Vehicle {
  final String plateNumber;
  final String model;
  final String color;

  Vehicle(
      {required this.plateNumber, required this.model, required this.color});

  factory Vehicle.fromMap(Map<String, dynamic> data) {
    return Vehicle(
      plateNumber: data['plateNumber'],
      model: data['model'],
      color: data['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plateNumber': plateNumber,
      'model': model,
      'color': color,
    };
  }
}
