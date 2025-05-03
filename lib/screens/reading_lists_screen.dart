import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingListsScreen extends StatefulWidget {
  @override
  _ReadingListsScreenState createState() => _ReadingListsScreenState();
}

class _ReadingListsScreenState extends State<ReadingListsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  final List<String> statuses = ['want', 'current', 'finished'];
  final List<String> tabLabels = ['Want', 'Current', 'Finished'];

  @override
  void initState() {
    _tabController = TabController(length: statuses.length, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Center(child: Text("Please login to view your reading lists")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("My Reading Lists"),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: statuses.map((status) => buildReadingList(status)).toList(),
      ),
    );
  }

  Widget buildReadingList(String status) {
    final stream =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('readingLists')
            .where('status', isEqualTo: status)
            .orderBy('timestamp', descending: true)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty)
          return Center(
            child: Text(
              "No books in ${status[0].toUpperCase()}${status.substring(1)} list.",
            ),
          );

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading:
                    data['thumbnail'] != null
                        ? Image.network(
                          data['thumbnail'],
                          width: 50,
                          fit: BoxFit.cover,
                        )
                        : Icon(Icons.book),
                title: Text(data['title'] ?? 'No Title'),
                subtitle: Text(data['author'] ?? 'Unknown Author'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: "Remove from list",
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('readingLists')
                        .doc(doc.id)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Book removed from your list.")),
                    );
                  },
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/bookDetail',
                    arguments: {
                      'bookId': doc.id,
                      'bookData': {
                        'id': doc.id,
                        'title': data['title'],
                        'authors': data['author'],
                        'thumbnail': data['thumbnail'],
                        // Add more fields if needed
                      },
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
