import 'package:flutter/material.dart';

class BookDetailScreen extends StatelessWidget {
  final String dummySummary = "This is a quick AI-powered summary of the book.";
  final String dummyBlurb =
      "You'll like this if you enjoy deep storytelling and thrilling narratives.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book Details")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 180,
                color: Colors.grey[300],
                child: Icon(Icons.book, size: 80),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Title: Dummy Book",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("AI Summary:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(dummySummary),
            SizedBox(height: 10),
            Text(
              "Why You'll Like This:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(dummyBlurb),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Add to reading list
              },
              child: Text("Add to List"),
            ),
            SizedBox(height: 20),
            Divider(),
            Text(
              "Reviews:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: Text("John Doe"),
              subtitle: Text("Really loved this book! Highly recommend."),
              trailing: Icon(Icons.star, color: Colors.amber),
            ),
            ListTile(
              title: Text("Jane Smith"),
              subtitle: Text("An interesting read but slow in the middle."),
              trailing: Icon(Icons.star_half, color: Colors.amber),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                child: Text("Write a Review"),
                onPressed: () {
                  _showReviewModal(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Write a Review"),
          content: TextField(
            decoration: InputDecoration(hintText: "Enter your review here"),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(onPressed: () {}, child: Text("Submit")),
          ],
        );
      },
    );
  }
}
