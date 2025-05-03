import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiscussionBoardScreen extends StatelessWidget {
 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(title: Text("Discussion Board")),
 body: StreamBuilder<QuerySnapshot>(
 stream: FirebaseFirestore.instance
 .collection('discussions')
 .orderBy('timestamp', descending: true)
 .snapshots(),
 builder: (context, snapshot) {
 if (!snapshot.hasData)
 return Center(child: CircularProgressIndicator());
 final topics = snapshot.data!.docs;
 return ListView.builder(
 itemCount: topics.length,
 itemBuilder: (context, index) {
 final data = topics[index].data() as Map<String, dynamic>;
 return Card(
 margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 child: ListTile(
 title: Text(data['title'] ?? ''),
 subtitle: Text("by ${data['author'] ?? 'Anonymous'}"),
 trailing: StreamBuilder<QuerySnapshot>(
 stream: FirebaseFirestore.instance
 .collection('discussions')
 .doc(topics[index].id)
 .collection('posts')
 .snapshots(),
 builder: (context, snapshot) {
 if (!snapshot.hasData) return SizedBox.shrink();
 return Text('${snapshot.data!.docs.length} replies');
 },
 ),
 onTap: () {
 Navigator.push(
 context,
 MaterialPageRoute(
 builder: (_) => DiscussionThreadScreen(
 topicId: topics[index].id,
 topicTitle: data['title'] ?? '',
 ),
 ),
 );
 },
 ),
 );
 },
 );
 },
 ),
 floatingActionButton: FloatingActionButton(
 onPressed: () => _showNewTopicDialog(context),
 child: Icon(Icons.add_comment),
 tooltip: "Start a new topic",
 ),
 );
 }

 void _showNewTopicDialog(BuildContext context) {
 final TextEditingController _controller = TextEditingController();
 final user = FirebaseAuth.instance.currentUser;

 showDialog(
 context: context,
 builder: (_) => AlertDialog(
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
 onPressed: () async {
 if (_controller.text.trim().isEmpty) return;
 await FirebaseFirestore.instance.collection('discussions').add({
 'title': _controller.text.trim(),
 'author': user?.email ?? 'Anonymous',
 'timestamp': FieldValue.serverTimestamp(),
 });
 Navigator.pop(context);
 },
 child: Text("Post"),
 ),
 ],
 ),
 );
 }
}

class DiscussionThreadScreen extends StatefulWidget {
 final String topicId;
 final String topicTitle;
 DiscussionThreadScreen({required this.topicId, required this.topicTitle});

 @override
 _DiscussionThreadScreenState createState() => _DiscussionThreadScreenState();
}

class _DiscussionThreadScreenState extends State<DiscussionThreadScreen> {
 final TextEditingController _replyController = TextEditingController();
 final user = FirebaseAuth.instance.currentUser;

 @override
 Widget build(BuildContext context) {
 final postsStream = FirebaseFirestore.instance
 .collection('discussions')
 .doc(widget.topicId)
 .collection('posts')
 .orderBy('timestamp', descending: false)
 .snapshots();

 return Scaffold(
 appBar: AppBar(title: Text(widget.topicTitle)),
 body: Column(
 children: [
 Expanded(
 child: StreamBuilder<QuerySnapshot>(
 stream: postsStream,
 builder: (context, snapshot) {
 if (!snapshot.hasData)
 return Center(child: CircularProgressIndicator());
 final posts = snapshot.data!.docs;
 if (posts.isEmpty)
 return Center(child: Text("No replies yet."));
 return ListView.builder(
 itemCount: posts.length,
 itemBuilder: (_, i) {
 final data = posts[i].data() as Map<String, dynamic>;
 return ListTile(
 title: Text(data['text'] ?? ''),
 subtitle: Text("by ${data['author'] ?? 'Anonymous'}"),
 );
 },
 );
 },
 ),
 ),
 Divider(height: 1),
 Padding(
 padding: const EdgeInsets.all(8.0),
 child: Row(
 children: [
 Expanded(
 child: TextField(
 controller: _replyController,
 decoration: InputDecoration(
 hintText: "Write a reply...",
 border: OutlineInputBorder(),
 ),
 ),
 ),
 SizedBox(width: 8),
 ElevatedButton(
 onPressed: () async {
 if (_replyController.text.trim().isEmpty) return;
 await FirebaseFirestore.instance
 .collection('discussions')
 .doc(widget.topicId)
 .collection('posts')
 .add({
 'text': _replyController.text.trim(),
 'author': user?.email ?? 'Anonymous',
 'timestamp': FieldValue.serverTimestamp(),
 });
 _replyController.clear();
 },
 child: Text("Send"),
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }
}

