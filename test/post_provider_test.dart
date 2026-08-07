import 'package:flutter_blog_app/data/post.dart';
import 'package:flutter_blog_app/providers/post_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostProvider ownership checks', () {
    test('allows management when the current user owns the post', () {
      final provider = PostProvider();
      final post = Post(
        id: 1,
        userId: 'user-123',
        title: 'Hello',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Body',
        imageUrls: const [],
        commentsCount: 0,
        viewsCount: 0,
      );

      expect(
        provider.canManagePost(post: post, currentUserId: 'user-123'),
        isTrue,
      );
    });

    test('blocks management when the current user is not the owner', () {
      final provider = PostProvider();
      final post = Post(
        id: 1,
        userId: 'user-123',
        title: 'Hello',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Body',
        imageUrls: const [],
        commentsCount: 0,
        viewsCount: 0,
      );

      expect(
        provider.canManagePost(post: post, currentUserId: 'user-456'),
        isFalse,
      );
    });

    test('copyWith updates comment and view stats', () {
      final post = Post(
        id: 1,
        userId: 'user-123',
        title: 'Hello',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Body',
        imageUrls: const [],
        commentsCount: 1,
        viewsCount: 3,
      );

      final updatedPost = post.copyWith(commentsCount: 4, viewsCount: 7);

      expect(updatedPost.commentsCount, 4);
      expect(updatedPost.viewsCount, 7);
      expect(updatedPost.id, post.id);
    });
  });
}
