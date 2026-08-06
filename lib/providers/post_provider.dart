import 'package:flutter/material.dart';
import 'package:flutter_blog_app/data/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostProvider extends ChangeNotifier {
  Future<List<Post>> getPublicPosts() async {
    final response = await Supabase.instance.client.from('posts').select();
    print(response);
    return response
        .map(
          (data) => Post(
            id: data['id'],
            userId: data['user_id'].toString(),
            title: data['title'],
            description: data['description'],
            createdAt: DateTime.parse(data['created_at']),
            updatedAt: DateTime.parse(data['updated_at']),
            imageUrls: List<String>.from(data['image_urls']),
          ),
        )
        .toList();
  }

  Future<Post?> getPostById(int postId) async {
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select()
          .eq('id', postId)
          .single();

      return Post(
        id: response['id'],
        userId: response['user_id'].toString(),
        title: response['title'],
        description: response['description'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        imageUrls: List<String>.from(response['image_urls']),
      );
    } catch (e) {
      print('Error fetching post by ID: $e');
      return null;
    }
  }
}
