import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchScreen extends StatefulWidget {
 @override
 _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
 String query = '';
 List<Map<String, dynamic>> results = [];
 bool loading = false;

 Future<void> _searchBooks(String q) async {
 setState(() {
 loading = true;
 results = [];
 });
 final url = Uri.parse(
 'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(q)}&key=AIzaSyCNOR5YsIsuRRfnsvTUvICYKVl50VVtXfo',
 );
 final response = await http.get(url);
 if (response.statusCode == 200) {
 final data = json.decode(response.body);
 final items = data['items'] as List?;
 setState(() {
 results =
 items?.map<Map<String, dynamic>>((item) {
 final volume = item['volumeInfo'];
 return {
 'id': item['id'],
 'title': volume['title'],
 'authors': (volume['authors'] as List?)?.join(', ') ?? '',
 'thumbnail': volume['imageLinks']?['thumbnail'],
 'description': volume['description'] ?? '',
 'publishedDate': volume['publishedDate'] ?? '',
 'averageRating': volume['averageRating']?.toString() ?? '',
 };
 }).toList() ??
 [];
 loading = false;
 });
 } else {
 setState(() {
 loading = false;
 });
 ScaffoldMessenger.of(
 context,
 ).showSnackBar(SnackBar(content: Text('Failed to fetch books')));
 }
 }

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(title: Text("Search Books")),
 body: Padding(
 padding: const EdgeInsets.all(16.0),
 child: Column(
 children: [
 TextField(
 decoration: InputDecoration(
 labelText: "Search by title or author",
 border: OutlineInputBorder(),
 ),
 onChanged: (val) {
 setState(() => query = val);
 if (val.trim().isNotEmpty) _searchBooks(val.trim());
 },
 ),
 SizedBox(height: 16),
 if (loading) CircularProgressIndicator(),
 if (!loading)
 Expanded(
 child: ListView.builder(
 itemCount: results.length,
 itemBuilder: (_, i) {
 final book = results[i];
 return ListTile(
 leading: book['thumbnail'] != null
 ? Image.network(book['thumbnail'], width: 40)
 : Icon(Icons.book),
 title: Text(book['title'] ?? ''),
 subtitle: Text(book['authors'] ?? ''),
 onTap: () {
 Navigator.pushNamed(
 context,
 '/bookDetail',
 arguments: {
 'bookId': book['id'],
 'bookData': book, // Always pass the full book data!
 },
 );
 },
 );
 },
 ),
 ),
 ],
 ),
 ),
 );
 }
}

