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

  final Map<String, String> tabToStatus = {
    'Want': 'want',
    'Current': 'current',
    'Finished': 'finished',
  };

  @override
  void initState() {
    _tabController = TabController(length: tabToStatus.length, vsync: this);
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
          tabs: tabToStatus.keys.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            tabToStatus.values
                .map((status) => buildReadingList(status))
                .toList(),
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
            child: Text("No books in ${status.toUpperCase()} list."),
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
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => handleMenuAction(value, doc.id),
                  itemBuilder:
                      (context) => [
                        if (status != 'want')
                          PopupMenuItem(
                            value: 'want',
                            child: Text("Move to Want"),
                          ),
                        if (status != 'current')
                          PopupMenuItem(
                            value: 'current',
                            child: Text("Move to Current"),
                          ),
                        if (status != 'finished')
                          PopupMenuItem(
                            value: 'finished',
                            child: Text("Move to Finished"),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text("Remove from List"),
                        ),
                      ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/bookDetail',
                    arguments: {'bookId': doc.id},
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void handleMenuAction(String action, String bookId) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('readingLists')
        .doc(bookId);

    if (action == 'delete') {
      await docRef.delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Book removed from your list.")));
    } else {
      await docRef.update({'status': action});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Book moved to ${action.toUpperCase()} list.")),
      );
    }
  }
}
