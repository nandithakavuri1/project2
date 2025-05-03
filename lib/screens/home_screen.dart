import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String query = '';
  List<Map<String, dynamic>> results = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialBooks();
  }

  Future<void> _loadInitialBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final genres = prefs.getStringList('preferredGenres');
    String initialQuery;
    if (genres != null && genres.isNotEmpty) {
      // You can join multiple genres for a broader search, or just use the first
      initialQuery = genres.join(' OR ');
    } else {
      initialQuery = 'bestsellers'; // fallback default
    }
    await _searchBooks(initialQuery, isInitial: true);
  }

  Future<void> _searchBooks(String q, {bool isInitial = false}) async {
    setState(() {
      loading = true;
      if (!isInitial) results = [];
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("BookMate"),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              _loadInitialBooks(); // Reload books after returning from profile
            },
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () => Navigator.pushNamed(context, '/lists'),
          ),
          IconButton(
            icon: Icon(Icons.forum),
            onPressed: () => Navigator.pushNamed(context, '/discussion'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Search books by title or author",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
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
                child:
                    results.isEmpty
                        ? Center(
                          child: Text(
                            "No books found. Try searching or update your preferences!",
                          ),
                        )
                        : ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final book = results[i];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading:
                                    book['thumbnail'] != null
                                        ? Image.network(
                                          book['thumbnail'],
                                          width: 50,
                                        )
                                        : Icon(Icons.book, size: 50),
                                title: Text(book['title'] ?? ''),
                                subtitle: Text(book['authors'] ?? ''),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/bookDetail',
                                    arguments: {
                                      'bookId': book['id'],
                                      'bookData': book,
                                    },
                                  );
                                },
                              ),
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
