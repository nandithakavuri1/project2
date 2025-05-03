import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  BookDetailScreen({this.bookId = 'gone_girl'}); // Default for testing

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 4.0;
  bool isInReadingList = false;
  bool loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initPage();
  }

  Future<void> _initPage() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final bookId = args?['bookId'] ?? '';
    final user = FirebaseAuth.instance.currentUser;
    print('BookDetailScreen _initPage: user=$user, bookId=$bookId');
    if (user == null || bookId == '') {
      setState(() {
        isInReadingList = false;
        loading = false;
      });
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('readingLists')
              .doc(bookId)
              .get();
      print('Firestore doc.exists: ${doc.exists}');
      setState(() {
        isInReadingList = doc.exists;
      });
    } catch (e) {
      print('Error fetching reading list: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<String> summarizeReviews(List<String> reviews) async {
    final apiKey = 'KTEbZcrkdjTGIMWi3JdOUCN0Tu4D4PrisVbejVbH';
    final response = await http.post(
      Uri.parse('https://api.cohere.ai/v1/summarize'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': reviews.join('\n'),
        'length': 'medium',
        'format': 'paragraph',
        'model': 'summarize-xlarge',
      }),
    );
    print('Cohere status: ${response.statusCode}');
    print('Cohere body: ${response.body}');
    final data = jsonDecode(response.body);
    return data['summary'] ?? 'No summary available';
  }

  void _showReviewDialog(String bookId) {
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
                        _showReviewDialog(bookId);
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
              ElevatedButton(
                child: Text("Submit"),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null || _reviewController.text.trim().isEmpty)
                    return;

                  await FirebaseFirestore.instance
                      .collection('books')
                      .doc(bookId)
                      .collection('reviews')
                      .add({
                        'user': user.email,
                        'rating': _rating,
                        'text': _reviewController.text.trim(),
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                  _reviewController.clear();
                  Navigator.pop(context); // Only pop the dialog
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Review submitted!")));

                  print('Adding review to books/$bookId/reviews');
                },
              ),
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
        title: Text("Rating: ${data['rating'] ?? '?'} ?"),
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
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final bookData = args?['bookData'];
    final bookId = args?['bookId'] ?? '';

    print('BookDetailScreen: bookId=$bookId');

    if (bookData == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Book Details"), leading: BackButton()),
        body: Center(
          child: Text("Book data not found. Please try searching again."),
        ),
      );
    }

    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(bookData['title'] ?? "Book Details"),
          leading: BackButton(),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final reviewStream =
        FirebaseFirestore.instance
            .collection('books')
            .doc(bookId)
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(bookData['title'] ?? "Book Details"),
        leading: BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (bookData['thumbnail'] != null)
              Center(child: Image.network(bookData['thumbnail'], height: 180)),
            SizedBox(height: 16),
            Text(
              bookData['title'] ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              "by ${bookData['authors'] ?? ''}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            if (bookData['publishedDate'] != null)
              Text("Published: ${bookData['publishedDate']}"),
            if (bookData['averageRating'] != null &&
                bookData['averageRating'] != '')
              Text("Rating: ${bookData['averageRating']} ?"),
            SizedBox(height: 16),
            if (bookData['description'] != null)
              Text(bookData['description'], style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            isInReadingList
                ? ElevatedButton.icon(
                  icon: Icon(Icons.check, color: Colors.white),
                  label: Text("Added"),
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                )
                : ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("Add to My Reading List"),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please login to add books.")),
                      );
                      return;
                    }
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('readingLists')
                        .doc(bookId)
                        .set({
                          'title': bookData['title'],
                          'author': bookData['authors'],
                          'thumbnail': bookData['thumbnail'],
                          'status': 'want',
                          'timestamp': FieldValue.serverTimestamp(),
                          'googleBookId': bookId,
                        });
                    setState(() {
                      isInReadingList = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Book added to your reading list!"),
                      ),
                    );
                  },
                ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showReviewDialog(bookId),
                icon: Icon(Icons.rate_review),
                label: Text("Write a Review"),
              ),
            ),
            Divider(height: 30),
            Text("Reviews", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: reviewStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                final reviews = snapshot.data?.docs ?? [];
                final reviewTexts =
                    reviews
                        .map(
                          (doc) =>
                              (doc.data() as Map<String, dynamic>)['text'] ??
                              '',
                        )
                        .where((text) => text.toString().trim().isNotEmpty)
                        .cast<String>()
                        .toList();

                if (reviewTexts.isEmpty) {
                  return Text("No reviews yet. Be the first!");
                }

                // Use a FutureBuilder to show the summary
                return FutureBuilder<String>(
                  future: summarizeReviews(reviewTexts),
                  builder: (context, summarySnapshot) {
                    if (summarySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "AI-Generated Summary of Reviews:",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(),
                        ],
                      );
                    }
                    if (summarySnapshot.hasError) {
                      return Text("Failed to summarize reviews.");
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AI-Generated Summary of Reviews:",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
                        Text(summarySnapshot.data ?? "No summary available."),
                        Divider(height: 30),
                        Text(
                          "All Reviews",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          itemBuilder:
                              (_, index) => _buildReviewCard(reviews[index]),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
