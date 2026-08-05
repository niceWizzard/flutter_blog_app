import 'package:flutter/material.dart';
import 'package:flutter_blog_app/providers/post_provider.dart';
import 'package:provider/provider.dart';

class PostsTab extends StatelessWidget {
  const PostsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostProvider>().posts;

    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return ListTile(
            title: Text(post.title),
            subtitle: Text(post.description),
          );
        },
      ),
    );
  }
}
