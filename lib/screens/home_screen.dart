import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final List<String> genres = [
    'Fiction',
    'Mystery',
    'Fantasy',
    'Sci-Fi',
    'Non-Fiction',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("For You")),
      body: Column(
        children: [
          Container(
            height: 50,
            margin: EdgeInsets.all(10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: genres.map((g) => Chip(label: Text(g))).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (_, index) {
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text("Top Pick #${index + 1}"),
                    subtitle: Text(
                      "AI suggests this based on your preferences.",
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/bookDetail');
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lists'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
