import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<String> dummyResults = [
    "Atomic Habits",
    "The Alchemist",
    "1984",
    "Sapiens",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search books...",
            border: InputBorder.none,
          ),
          onChanged: (query) {
            // Later: add dynamic search logic here
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Add filter logic popup (genre, author, rating)
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: dummyResults.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.book),
            title: Text(dummyResults[index]),
            onTap: () {
              Navigator.pushNamed(context, '/bookDetail');
            },
          );
        },
      ),
    );
  }
}
