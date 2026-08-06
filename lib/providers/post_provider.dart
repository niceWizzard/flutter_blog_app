import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blog_app/data/post.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostProvider extends ChangeNotifier {
  String? get currentUserId =>
      Supabase.instance.client.auth.currentSession?.user.id;

  bool canManagePost({required Post post, required String? currentUserId}) {
    if (currentUserId == null) {
      return false;
    }

    return post.userId == currentUserId;
  }

  Future<List<Post>> getPublicPosts({int limit = 10, int offset = 0}) async {
    final response = await Supabase.instance.client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

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

  Future<int> getPublicPostsCount() async {
    final response = await Supabase.instance.client
        .from('posts')
        .select('id')
        .count();
    return response.count;
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

  Future<void> updatePost({
    required int postId,
    required String title,
    required String description,
    required List<String> existingImageUrls,
    required List<XFile> newImages,
    required List<String> removedImageUrls,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be signed in to update a post.');
    }

    final existingPost = await Supabase.instance.client
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .maybeSingle();

    if (existingPost == null || existingPost['user_id'].toString() != userId) {
      throw Exception('You can only edit your own posts.');
    }

    final finalImageUrls = <String>[];
    final imagesToKeep = <String>[];

    for (final imageUrl in existingImageUrls) {
      if (!removedImageUrls.contains(imageUrl)) {
        imagesToKeep.add(imageUrl);
      }
    }

    finalImageUrls.addAll(imagesToKeep);

    for (final image in newImages) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final storagePath = '$userId/$fileName';
      final file = File(image.path);
      final response = await Supabase.instance.client.storage
          .from('post-images')
          .upload(storagePath, file);

      final publicUrl = Supabase.instance.client.storage
          .from('post-images')
          .getPublicUrl(storagePath);

      if (response.isEmpty) {
        throw Exception('Unable to upload one or more images.');
      }
      finalImageUrls.add(publicUrl);
    }

    if (finalImageUrls.length > 5) {
      throw Exception('You can keep up to 5 images.');
    }

    await Supabase.instance.client
        .from('posts')
        .update({
          'title': title,
          'description': description,
          'image_urls': finalImageUrls,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId);

    notifyListeners();
  }

  Future<void> deletePost({required int postId}) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be signed in to delete a post.');
    }

    final existingPost = await Supabase.instance.client
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .maybeSingle();

    if (existingPost == null || existingPost['user_id'].toString() != userId) {
      throw Exception('You can only delete your own posts.');
    }

    await Supabase.instance.client.from('posts').delete().eq('id', postId);
    notifyListeners();
  }
}
