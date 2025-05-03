import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final genres = [
    'Fiction',
    'Non-Fiction',
    'Mystery',
    'Sci-Fi',
    'Fantasy',
    'Biography',
    'Self-Help',
  ];

  String? selectedGenre;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGenrePreference();
    _syncWithFirestore();
  }

  // 1️⃣ Load from SharedPreferences first
  Future<void> _loadGenrePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString('preferredGenre');
    if (local != null) {
      setState(() {
        selectedGenre = local;
        _loading = false;
      });
    }
  }

  // 2️⃣ Then fetch from Firestore (and overwrite if needed)
  Future<void> _syncWithFirestore() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final remote = doc.data()?['preferredGenre'] as String?;
    if (remote != null && remote != selectedGenre) {
      setState(() {
        selectedGenre = remote;
      });
      // Update local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferredGenre', remote);
    }
    // If no remote, write local → Firestore
    else if (remote == null && selectedGenre != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferredGenre': selectedGenre,
      }, SetOptions(merge: true));
    }
    setState(() => _loading = false);
  }

  // 3️⃣ Save both locally and remotely on change
  Future<void> _onGenreChanged(String? genre) async {
    if (genre == null) return;
    setState(() => selectedGenre = genre);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferredGenre', genre);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'preferredGenre': genre,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Genre saved: $genre")));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body:
          _loading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Preferred Genre",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedGenre,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      hint: Text("Select your favorite genre"),
                      items:
                          genres
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                      onChanged: _onGenreChanged,
                    ),
                    Spacer(),
                    SwitchListTile(
                      title: Text("Dark Mode"),
                      value: isDark,
                      onChanged:
                          (v) => setState(
                            () =>
                                themeNotifier.value =
                                    v ? ThemeMode.dark : ThemeMode.light,
                          ),
                    ),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed:
                            () => FirebaseAuth.instance.signOut().then(
                              (_) => Navigator.pushReplacementNamed(
                                context,
                                '/login',
                              ),
                            ),
                        icon: Icon(Icons.logout),
                        label: Text("Logout"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
