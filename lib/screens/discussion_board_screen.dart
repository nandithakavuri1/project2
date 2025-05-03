import 'package:flutter/material.dart';

class DiscussionBoardScreen extends StatelessWidget {
  // Temporary mock data — can be replaced with Firestore
  final List<String> topics = [
    "What book changed your life?",
    "Best reads of 2024?",
    "How do you pick your next book?",
    "Fantasy vs Sci-Fi debates",
    "Share your AI-generated book summaries",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Discussion Board")),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(Icons.forum),
              title: Text(topics[index]),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Placeholder route – create a thread view later
                Navigator.pushNamed(
                  context,
                  '/discussionThread',
                  arguments: topics[index],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewTopicDialog(context);
        },
        child: Icon(Icons.add_comment),
        tooltip: "Start a new topic",
      ),
    );
  }

  void _showNewTopicDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("New Discussion Topic"),
            content: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(hintText: "Enter topic title"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Posted: ${_controller.text}")),
                    );
                    // You can later push this topic to Firestore here
                  }
                },
                child: Text("Post"),
              ),
            ],
          ),
    );
  }
}
