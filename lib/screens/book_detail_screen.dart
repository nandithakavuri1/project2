import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  BookDetailScreen({this.bookId = 'gone_girl'}); // Default for testing

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 4.0;

  void _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _reviewController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('books')
        .doc(widget.bookId)
        .collection('reviews')
        .add({
          'user': user.email,
          'rating': _rating,
          'text': _reviewController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

    _reviewController.clear();
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Review submitted!")));
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Write a Review"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return IconButton(
                      icon: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = i + 1.0;
                        });
                        Navigator.pop(context);
                        _showReviewDialog();
                      },
                    );
                  }),
                ),
                // Review Text
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Share your thoughts...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                  _reviewController.clear();
                },
              ),
              ElevatedButton(child: Text("Submit"), onPressed: _submitReview),
            ],
          ),
    );
  }

  Widget _buildReviewCard(DocumentSnapshot review) {
    final data = review.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(Icons.star, color: Colors.amber),
        title: Text("Rating: ${data['rating'] ?? '?'} ⭐"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['text'] ?? ''),
            SizedBox(height: 4),
            Text(
              "- ${data['user'] ?? 'Anonymous'}",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          timestamp != null
              ? "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}"
              : "Just now",
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewStream =
        FirebaseFirestore.instance
            .collection('books')
            .doc(widget.bookId)
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text("Book Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookId.replaceAll('_', ' ').toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            Text(
              "AI Summary: A psychological thriller about a marriage gone wrong...",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showReviewDialog,
                icon: Icon(Icons.rate_review),
                label: Text("Write a Review"),
              ),
            ),
            Divider(height: 30),
            Text("Reviews", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: reviewStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());
                  final reviews = snapshot.data?.docs ?? [];
                  if (reviews.isEmpty)
                    return Text("No reviews yet. Be the first!");
                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (_, index) => _buildReviewCard(reviews[index]),
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
