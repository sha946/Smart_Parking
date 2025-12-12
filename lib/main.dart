import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/maps_page.dart';
import 'screens/profile_page.dart';
import 'screens/admin_dashboard.dart';
import 'screens/settings_page.dart';
import 'widget_test.dart';
import 'theme_manager.dart';
import 'screens/reservation.dart';
import 'screens/spots.dart';
import '../notification_service.dart';
import '../parking_monitor_service.dart';
import 'screens/mesreservations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  await NotificationService().initialize();

  //Démarrer la surveillance des places
  ParkingMonitorService().startMonitoring();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => ThemeManager())],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          // Attendre que le thème soit chargé
          if (!themeManager.isLoaded) {
            return MaterialApp(
              home: Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Chargement...'),
                    ],
                  ),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Smart Parking App',
            debugShowCheckedModeBanner: false,
            theme: ThemeManager.lightTheme,
            darkTheme: ThemeManager.darkTheme,
            themeMode: themeManager.themeMode,
            home: WidgetTree(),
            routes: {
              '/login': (context) => LoginPage(),
              '/home': (context) => HomePage(isAdmin: false),
              '/maps': (context) => MapsPage(),
              '/profile': (context) => ProfilePage(),
              '/admin': (context) => AdminDashboard(),
              '/settings': (context) => SettingsPage(),
              '/reservation': (context) => ReservationPage(),
              '/spots': (context) => SpotsPage(),
              '/mes_reservations': (context) => MesReservationsPage(),
            },
          );
        },
      ),
    );
  }
}
