import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/reading_lists_screen.dart';
import 'screens/discussion_board_screen.dart';
import 'screens/profile_screen.dart';

// Theme controller
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(BookMateApp());
}

class BookMateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'BookMate',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (context) => AuthWrapper(),
            '/login': (context) => LoginScreen(),
            '/home': (context) => HomeScreen(),
            '/search': (context) => SearchScreen(),
            '/lists': (context) => ReadingListsScreen(),
            '/discussion': (context) => DiscussionBoardScreen(),
            '/profile': (context) => ProfileScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/bookDetail') {
              return MaterialPageRoute(
                builder: (context) => BookDetailScreen(),
                settings: settings,
              );
            }
            return null;
          },
          onUnknownRoute:
              (_) => MaterialPageRoute(
                builder:
                    (_) => Scaffold(
                      body: Center(child: Text("404: Page not found")),
                    ),
              ),
        );
      },
    );
  }
}

// Auth logic to show login or home screen
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
