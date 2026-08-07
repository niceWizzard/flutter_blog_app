import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blog_app/data/post.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostProvider extends ChangeNotifier {
  String? get currentUserId =>
      Supabase.instance.client.auth.currentSession?.user.id;

  int _parseCount(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  bool canManagePost({required Post post, required String? currentUserId}) {
    if (currentUserId == null) {
      return false;
    }

    return post.userId == currentUserId;
  }

  Future<List<PostComment>> getCommentsForPost(int postId) async {
    final response = await Supabase.instance.client
        .from('comments')
        .select(
          'id, post_id, user_id, content, image_url, created_at, profiles(name)',
        )
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return response.map((data) {
      final profileData = data['profiles'];
      final profileName = profileData is Map
          ? profileData['name']?.toString() ?? ''
          : '';
      final userId = data['user_id']?.toString() ?? '';

      return PostComment(
        id: data['id'],
        postId: data['post_id'],
        userId: userId,
        content: data['content']?.toString() ?? '',
        imageUrl: data['image_url']?.toString(),
        createdAt: DateTime.parse(data['created_at']),
        commenterName: profileName.isNotEmpty ? profileName : userId,
      );
    }).toList();
  }

  Future<List<Post>> getPublicPosts({int limit = 10, int offset = 0}) async {
    final response = await Supabase.instance.client
        .from('posts')
        .select('*, comments(count), user_post_view(count)')
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    final posts = response.map((data) {
      final postId = data['id'] as int;
      final commentsCount = data['comments'][0]['count'] as int? ?? 0;
      final viewsCount = data['user_post_view'][0]['count'] as int? ?? 0;
      return Post(
        id: postId,
        userId: data['user_id'].toString(),
        title: data['title'],
        description: data['description'],
        createdAt: DateTime.parse(data['created_at']),
        updatedAt: DateTime.parse(data['updated_at']),
        imageUrls: List<String>.from(data['image_urls'] ?? const []),
        commentsCount: commentsCount,
        viewsCount: viewsCount,
      );
    }).toList();

    return posts;
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
          .select('*, comments(count), user_post_view(count)')
          .eq('id', postId)
          .single();

      return Post(
        id: response['id'],
        userId: response['user_id'].toString(),
        title: response['title'],
        description: response['description'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        imageUrls: List<String>.from(response['image_urls'] ?? const []),
        commentsCount: response['comments'][0]['count'] as int? ?? 0,
        viewsCount: response['user_post_view'][0]['count'] as int? ?? 0,
      );
    } catch (e) {
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

  Future<void> addComment({
    required int postId,
    required String content,
    XFile? image,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be signed in to comment.');
    }

    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty && image == null) {
      throw Exception('Please add a comment or an image.');
    }

    String? imageUrl;
    if (image != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final storagePath = '$userId/$fileName';
      final file = File(image.path);
      final response = await Supabase.instance.client.storage
          .from('post-images')
          .upload(storagePath, file);

      if (response.isEmpty) {
        throw Exception('Unable to upload the comment image.');
      }

      imageUrl = Supabase.instance.client.storage
          .from('post-images')
          .getPublicUrl(storagePath);
    }

    await Supabase.instance.client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': trimmedContent,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    });

    try {
      final currentRow = await Supabase.instance.client
          .from('posts')
          .select('comments_count')
          .eq('id', postId)
          .maybeSingle();
      final currentCount = _parseCount(currentRow?['comments_count']);

      await Supabase.instance.client
          .from('posts')
          .update({
            'comments_count': currentCount + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', postId);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> deleteComment({
    required int commentId,
    required int postId,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be signed in to delete a comment.');
    }

    final existingComment = await Supabase.instance.client
        .from('comments')
        .select('user_id')
        .eq('id', commentId)
        .maybeSingle();

    if (existingComment == null ||
        existingComment['user_id'].toString() != userId) {
      throw Exception('You can only delete your own comments.');
    }

    await Supabase.instance.client
        .from('comments')
        .delete()
        .eq('id', commentId);

    try {
      final currentRow = await Supabase.instance.client
          .from('posts')
          .select('comments_count')
          .eq('id', postId)
          .maybeSingle();
      final currentCount = _parseCount(currentRow?['comments_count']);

      await Supabase.instance.client
          .from('posts')
          .update({
            'comments_count': currentCount > 0 ? currentCount - 1 : 0,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', postId);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> updateComment({
    required int commentId,
    required int postId,
    required String content,
    String? imageUrl,
    bool removeImage = false,
    XFile? newImage,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be signed in to edit a comment.');
    }

    final existingComment = await Supabase.instance.client
        .from('comments')
        .select('user_id')
        .eq('id', commentId)
        .maybeSingle();

    if (existingComment == null ||
        existingComment['user_id'].toString() != userId) {
      throw Exception('You can only edit your own comments.');
    }

    String? resolvedImageUrl = imageUrl;
    if (removeImage) {
      resolvedImageUrl = null;
    }

    if (newImage != null) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${newImage.name}';
      final storagePath = '$userId/$fileName';
      final file = File(newImage.path);
      final response = await Supabase.instance.client.storage
          .from('post-images')
          .upload(storagePath, file);

      if (response.isEmpty) {
        throw Exception('Unable to upload the comment image.');
      }

      resolvedImageUrl = Supabase.instance.client.storage
          .from('post-images')
          .getPublicUrl(storagePath);
    }

    await Supabase.instance.client
        .from('comments')
        .update({'content': content.trim(), 'image_url': resolvedImageUrl})
        .eq('id', commentId);

    notifyListeners();
  }

  Future<void> incrementPostViews({required int postId}) async {
    final userId = currentUserId;
    if (userId == null) {
      return;
    }

    try {
      await Supabase.instance.client.from('user_post_view').upsert({
        'post_id': postId,
        'user_id': userId,
      });
    } catch (_) {}

    notifyListeners();
  }
}
