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
 User? user;
 final genres = [
 'Fiction',
 'Non-Fiction',
 'Mystery',
 'Sci-Fi',
 'Fantasy',
 'Biography',
 'Self-Help',
 ];

 List<String> selectedGenres = [];
 bool _loading = true;
 final _displayNameController = TextEditingController();
 final _emailController = TextEditingController();
 final _passwordController = TextEditingController();

 @override
 void initState() {
 super.initState();
 user = FirebaseAuth.instance.currentUser;
 if (user != null) {
 _displayNameController.text = user!.displayName ?? '';
 _emailController.text = user!.email ?? '';
 _loadGenrePreference().then((_) => _syncWithFirestore());
 } else {
 setState(() => _loading = false);
 }
 }

 // 1?? Load from SharedPreferences first
 Future<void> _loadGenrePreference() async {
 final prefs = await SharedPreferences.getInstance();
 final local = prefs.getStringList('preferredGenres');
 if (local != null) {
 setState(() {
 selectedGenres = local;
 });
 }
 }

 // 2?? Then fetch from Firestore (and overwrite if needed)
 Future<void> _syncWithFirestore() async {
 if (user == null) {
 setState(() => _loading = false);
 return;
 }
 try {
 final doc = await FirebaseFirestore.instance
 .collection('users')
 .doc(user!.uid)
 .get();

 final remote = (doc.data()?['preferredGenres'] as List?)?.cast<String>();
 if (remote != null && !_listsEqual(remote, selectedGenres)) {
 setState(() {
 selectedGenres = remote;
 });
 // Update local cache
 final prefs = await SharedPreferences.getInstance();
 await prefs.setStringList('preferredGenres', remote);
 } else if (remote == null && selectedGenres.isNotEmpty) {
 await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
 {'preferredGenres': selectedGenres},
 SetOptions(merge: true),
 );
 }
 } catch (e) {
 // Optionally handle error
 } finally {
 setState(() => _loading = false);
 }
 }

 // 3?? Save both locally and remotely on change
 Future<void> _onGenresChanged(List<String> genres) async {
 setState(() => selectedGenres = genres);

 final prefs = await SharedPreferences.getInstance();
 await prefs.setStringList('preferredGenres', genres);

 await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
 'preferredGenres': genres,
 }, SetOptions(merge: true));

 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text("Genres saved: ${genres.join(', ')}")),
 );
 }

 bool _listsEqual(List<String> a, List<String> b) {
 if (a.length != b.length) return false;
 final aSorted = List<String>.from(a)..sort();
 final bSorted = List<String>.from(b)..sort();
 for (int i = 0; i < aSorted.length; i++) {
 if (aSorted[i] != bSorted[i]) return false;
 }
 return true;
 }

 Future<void> _updateProfile() async {
 if (user == null) return;
 setState(() => _loading = true);
 try {
 if (_displayNameController.text.trim().isNotEmpty) {
 await user!.updateDisplayName(_displayNameController.text.trim());
 }
 if (_emailController.text.trim().isNotEmpty &&
 _emailController.text.trim() != user!.email) {
 await user!.updateEmail(_emailController.text.trim());
 }
 if (_passwordController.text.trim().isNotEmpty) {
 await user!.updatePassword(_passwordController.text.trim());
 }
 await user!.reload();
 user = FirebaseAuth.instance.currentUser;
 ScaffoldMessenger.of(
 context,
 ).showSnackBar(SnackBar(content: Text("Profile updated!")));
 } on FirebaseAuthException catch (e) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text("Error updating profile: ${e.message}")),
 );
 } finally {
 setState(() => _loading = false);
 }
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final isDark = theme.brightness == Brightness.dark;

 if (user == null) {
 return Scaffold(body: Center(child: Text("Not logged in.")));
 }

 return Scaffold(
 appBar: AppBar(title: Text("Profile")),
 body: _loading
 ? Center(child: CircularProgressIndicator())
 : Padding(
 padding: const EdgeInsets.all(16),
 child: SingleChildScrollView(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 "Preferred Genres",
 style: TextStyle(
 fontSize: 16,
 fontWeight: FontWeight.bold,
 ),
 ),
 SizedBox(height: 8),
 Wrap(
 spacing: 8,
 children: genres.map((genre) {
 final selected = selectedGenres.contains(genre);
 return FilterChip(
 label: Text(genre),
 selected: selected,
 onSelected: (bool value) {
 final newGenres = List<String>.from(selectedGenres);
 if (value) {
 newGenres.add(genre);
 } else {
 newGenres.remove(genre);
 }
 _onGenresChanged(newGenres);
 },
 );
 }).toList(),
 ),
 SizedBox(height: 24),
 Text(
 "Update Profile",
 style: TextStyle(
 fontSize: 16,
 fontWeight: FontWeight.bold,
 ),
 ),
 TextFormField(
 controller: _displayNameController,
 decoration: InputDecoration(labelText: "Display Name"),
 ),
 TextFormField(
 controller: _emailController,
 decoration: InputDecoration(labelText: "Email"),
 ),
 TextFormField(
 controller: _passwordController,
 decoration: InputDecoration(labelText: "New Password"),
 obscureText: true,
 ),
 SizedBox(height: 10),
 ElevatedButton(
 onPressed: _updateProfile,
 child: Text("Update Profile"),
 ),
 SizedBox(height: 24),
 SwitchListTile(
 title: Text("Dark Mode"),
 value: isDark,
 onChanged: (v) => setState(
 () => themeNotifier.value = v
 ? ThemeMode.dark
 : ThemeMode.light,
 ),
 ),
 SizedBox(height: 32),
 Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 ElevatedButton.icon(
 onPressed: () async {
 final prefs = await SharedPreferences.getInstance();
 await prefs.clear(); // Clear all local preferences
 await FirebaseAuth.instance.signOut();
 Navigator.pushReplacementNamed(context, '/login');
 },
 icon: Icon(Icons.logout, color: Colors.white),
 label: Text(
 "Logout",
 style: TextStyle(color: Colors.white),
 ),
 style: ElevatedButton.styleFrom(
 backgroundColor: Theme.of(
 context,
 ).colorScheme.secondary,
 padding: EdgeInsets.symmetric(
 horizontal: 24,
 vertical: 12,
 ),
 textStyle: TextStyle(
 fontSize: 16,
 fontWeight: FontWeight.bold,
 ),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(8),
 ),
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 ),
 );
 }
}

