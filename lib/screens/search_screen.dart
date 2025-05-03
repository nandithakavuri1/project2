import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    final url =
        'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _results = data['items'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch books.")));
    }
  }

  void _goToDetail(Map<String, dynamic> book) {
    final id = book['id'] ?? book['volumeInfo']['title'];
    Navigator.pushNamed(context, '/bookDetail', arguments: {'bookId': id});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Books")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: (_) => _searchBooks(),
              decoration: InputDecoration(
                labelText: "Search by title or author",
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchBooks,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, index) {
                      final book = _results[index];
                      final info = book['volumeInfo'];
                      final image = info['imageLinks']?['thumbnail'];
                      final title = info['title'] ?? 'No Title';
                      final author =
                          (info['authors'] != null)
                              ? (info['authors'] as List).join(", ")
                              : 'Unknown Author';
                      final rating = info['averageRating']?.toString() ?? '—';

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading:
                              image != null
                                  ? Image.network(
                                    image,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  )
                                  : Icon(Icons.book),
                          title: Text(title),
                          subtitle: Text("by $author\nRating: $rating"),
                          isThreeLine: true,
                          onTap: () => _goToDetail(book),
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
