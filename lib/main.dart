import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/scanned_profile_screen.dart';
import 'widgets/bottom_nav.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
            initialLocation: '/login',
            refreshListenable: auth, // 👈 add this
            redirect: (ctx, state) {
              debugPrint("🔄 Redirect check: loggedIn=${auth.loggedIn}, "
                  "loading=${auth.loading}, "
                  "location=${state.matchedLocation}");

              // Wait until AuthProvider finishes any async init
              if (auth.loading) return null;

              final loggedIn = auth.loggedIn;
              final isLoginPage = state.matchedLocation == '/login';

              if (!loggedIn) {
                return isLoginPage ? null : '/login';
              }

              if (loggedIn && isLoginPage) {
                return '/';
              }

              return null;
            },

            routes: [
              GoRoute(path: '/', builder: (ctx, st) => const BottomNav()),
              GoRoute(
                  path: '/login', builder: (ctx, st) => const LoginScreen()),
              GoRoute(
                  path: '/edit',
                  builder: (ctx, st) => const EditProfileScreen()),
              GoRoute(
                path: '/scanned',
                builder: (ctx, st) => ScannedProfileScreen(
                    data: st.extra as Map<String, dynamic>?),
              ),
            ],
          );

          return MaterialApp.router(
            title: 'SYNAPSE',
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              textTheme: GoogleFonts.ubuntuTextTheme(
                // <-- example font
                Theme.of(context).textTheme,
              ),
              colorSchemeSeed: Colors.blue,
              useMaterial3: true,
            ),
          );
        },
      ),
    );
  }
}
