import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get ref => _database.ref();
}
