import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blog_app/data/post.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> createPost({
    required String title,
    required String description,
    required List<XFile> images,
  }) async {
    final userId = Supabase.instance.client.auth.currentSession?.user.id;
    if (userId == null) {
      throw Exception('You must be signed in to create a post.');
    }

    final uploadedImageUrls = <String>[];

    for (final image in images) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final storagePath = '$userId/$fileName';
      final file = File(image.path);
      final response = await Supabase.instance.client.storage
          .from('post-images')
          .upload(storagePath, file);

      final publicUrl = Supabase.instance.client.storage
          .from('post-images')
          .getPublicUrl(storagePath);

      uploadedImageUrls.add(publicUrl);
      if (response.isEmpty) {
        throw Exception('Unable to upload one or more images.');
      }
    }

    await Supabase.instance.client.from('posts').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'image_urls': uploadedImageUrls,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    notifyListeners();
  }
}
