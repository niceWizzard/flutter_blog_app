import 'package:flutter/material.dart';
import 'package:flutter_blog_app/data/post.dart';

class PostProvider extends ChangeNotifier {
  final List<Post> posts = [
    Post(
      title: "Post 1",
      createdAt: DateTime(2026, 8, 5, 5),
      description: "This is the description of post 1",
      updatedAt: DateTime(2026, 8, 5, 5),
      imageUrls: [],
    ),
    Post(
      title: "Post 2",
      createdAt: DateTime(2026, 8, 5, 5),
      description: "This is the description of post 2",
      updatedAt: DateTime(2026, 8, 7, 5),
      imageUrls: [],
    ),
  ];

  Future<List<Post>> getPublicPosts() async {
    return Future.value([]);
  }
}
