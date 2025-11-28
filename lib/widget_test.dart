import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:flutter_application_1/screens/login_page.dart';
import '/auth_service.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final User user = snapshot.data!;
          final bool isAdmin = AuthService.isAdmin(user);

          // Pass user data to HomePage
          return HomePage(isAdmin: isAdmin, currentUser: user);
        } else {
          return LoginPage();
        }
      },
    );
  }
}
