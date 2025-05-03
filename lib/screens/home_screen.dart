import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> genres = [
    'Fiction',
    'Mystery',
    'Fantasy',
    'Sci-Fi',
    'Non-Fiction',
    'Thriller',
  ];

  final List<Map<String, String>> allBooks = [
    {'title': 'Gone Girl', 'genre': 'Thriller'},
    {'title': 'The Silent Patient', 'genre': 'Thriller'},
    {'title': 'Sapiens', 'genre': 'Non-Fiction'},
    {'title': 'Dune', 'genre': 'Sci-Fi'},
    {'title': 'The Hobbit', 'genre': 'Fantasy'},
    {'title': 'Sherlock Holmes', 'genre': 'Mystery'},
    {'title': 'To Kill a Mockingbird', 'genre': 'Fiction'},
  ];

  String selectedGenre = 'Thriller';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredBooks =
        allBooks.where((book) => book['genre'] == selectedGenre).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("For You"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            // Genre Dropdown
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: DropdownButtonFormField<String>(
                value: selectedGenre,
                dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                decoration: InputDecoration(
                  labelText: 'Select Genre',
                  labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                  border: OutlineInputBorder(),
                ),
                items:
                    genres.map((genre) {
                      return DropdownMenuItem(
                        value: genre,
                        child: Text(
                          genre,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedGenre = value;
                    });
                  }
                },
              ),
            ),

            // Book List
            Expanded(
              child:
                  filteredBooks.isEmpty
                      ? Center(
                        child: Text(
                          "No books in $selectedGenre",
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      )
                      : ListView.builder(
                        itemCount: filteredBooks.length,
                        itemBuilder: (_, index) {
                          final book = filteredBooks[index];
                          return Card(
                            color: isDark ? Colors.grey[850] : theme.cardColor,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.book,
                                color: theme.colorScheme.primary,
                              ),
                              title: Text(
                                book['title'] ?? '',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                "AI suggests this based on your preferences.",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/bookDetail',
                                  arguments: {
                                    'bookId': 'gone_girl',
                                  }, // or use dynamic book ID
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
        backgroundColor: isDark ? Colors.black : Colors.white,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) Navigator.pushNamed(context, '/lists');
          if (index == 2) Navigator.pushNamed(context, '/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lists'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
