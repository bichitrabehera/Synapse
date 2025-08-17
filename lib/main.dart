import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/scanned_profile_screen.dart';
import 'widgets/bottom_nav.dart';

void main() {
  runApp(const TapApp());
}

class TapApp extends StatelessWidget {
  const TapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final router = GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (ctx, st) => auth.loading
                    ? const Scaffold(
                        body: Center(child: CircularProgressIndicator()))
                    : auth.loggedIn
                        ? const BottomNav() // 👈 includes Home, Profile, Scanner
                        : const LoginScreen(),
                routes: [
                  GoRoute(
                      path: 'register',
                      builder: (ctx, st) => const RegisterScreen()),
                  GoRoute(
                      path: 'edit',
                      builder: (ctx, st) => const EditProfileScreen()),
                  GoRoute(
                      path: 'scanned',
                      builder: (ctx, st) =>
                          ScannedProfileScreen(data: st.extra)),
                ],
              ),
            ],
          );

          return MaterialApp.router(
            title: 'TapCard',
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorSchemeSeed: Colors.blue,
              useMaterial3: true,
            ),
          );
        },
      ),
    );
  }
}
