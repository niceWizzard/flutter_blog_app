import 'package:flutter/material.dart';
import 'package:flutter_blog_app/data/post.dart';
import 'package:flutter_blog_app/providers/post_provider.dart';
import 'package:flutter_blog_app/screens/create_post_screen.dart';
import 'package:flutter_blog_app/screens/posts_tab.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakePostProvider extends PostProvider {
  FakePostProvider(this.posts);

  final List<Post> posts;
  int getPublicPostsCallCount = 0;

  @override
  Future<List<Post>> getPublicPosts({int limit = 10, int offset = 0}) async {
    getPublicPostsCallCount++;
    final end = (offset + limit).clamp(0, posts.length);
    return posts.sublist(offset, end);
  }
}

void main() {
  testWidgets('Create post screen renders its form', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreatePostScreen()));

    expect(find.text('Create Post'), findsNWidgets(2));
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
  });

  testWidgets('Posts tab shows a load-more control when more pages exist', (
    tester,
  ) async {
    final provider = FakePostProvider(
      List.generate(
        15,
        (index) => Post(
          id: index + 1,
          userId: 'user-$index',
          title: 'Post $index',
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Description $index',
          imageUrls: const [],
        ),
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PostProvider>.value(
        value: provider,
        child: const MaterialApp(home: PostsTab()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(provider.getPublicPostsCallCount, 2);
  });
}
