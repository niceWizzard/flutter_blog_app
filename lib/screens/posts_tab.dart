import 'package:flutter/material.dart';
import 'package:flutter_blog_app/data/post.dart';
import 'package:flutter_blog_app/providers/post_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PostsTab extends StatefulWidget {
  const PostsTab({super.key});

  @override
  State<PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<PostsTab> {
  static const int _pageSize = 10;

  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalPosts = 0;
  List<Post> posts = [];

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  int get _totalPages {
    if (_totalPosts <= 0) return 1;
    return (_totalPosts / _pageSize).ceil();
  }

  List<int> get _visiblePageNumbers {
    final totalPages = _totalPages;
    if (totalPages <= 1) return [1];

    var start = _currentPage - 2;
    var end = _currentPage + 2;

    if (start < 1) {
      start = 1;
    }
    if (end > totalPages) {
      end = totalPages;
    }
    if (end - start + 1 < 5 && start > 1) {
      start = end - 4;
    }
    if (start < 1) {
      start = 1;
    }

    return List<int>.generate(end - start + 1, (index) => start + index);
  }

  Future<void> fetchPosts({int page = 1}) async {
    try {
      setState(() {
        _isLoading = true;
        _hasMore = true;
      });

      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final fetchedPosts = await postProvider.getPublicPosts(
        limit: _pageSize,
        offset: (page - 1) * _pageSize,
      );
      final totalPostsCount = await postProvider.getPublicPostsCount();

      if (!mounted) return;

      setState(() {
        posts = fetchedPosts;
        _currentPage = page;
        _totalPosts = totalPostsCount;
        _hasMore =
            fetchedPosts.length == _pageSize && _currentPage < _totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching posts: $e')));
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchPosts(page: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.pushNamed<bool>('create_post');
          if (created == true) {
            await fetchPosts(page: 1);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                ...posts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final post = entry.value;
                  final hasImage = post.imageUrls.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => context.pushNamed(
                          'post_detail',
                          pathParameters: {'postId': post.id.toString()},
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: hasImage
                                    ? Image.network(
                                        post.imageUrls.first,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, _, _) =>
                                            Container(
                                              width: 72,
                                              height: 72,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 32,
                                              ),
                                            ),
                                      )
                                    : Container(
                                        width: 72,
                                        height: 72,
                                        color: Colors
                                            .primaries[index %
                                                Colors.primaries.length]
                                            .shade200,
                                        child: Center(
                                          child: Text(
                                            post.title.isNotEmpty
                                                ? post.title[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      post.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[800]),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDate(post.createdAt),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                        const SizedBox(width: 12),
                                        if (post.imageUrls.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.photo,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${post.imageUrls.length} image${post.imageUrls.length > 1 ? 's' : ''}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Builder(
                                builder: (context) {
                                  final postProvider = context
                                      .read<PostProvider>();
                                  final canManage = postProvider.canManagePost(
                                    post: post,
                                    currentUserId: postProvider.currentUserId,
                                  );

                                  return PopupMenuButton<int>(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 1,
                                        child: Text('Edit'),
                                      ),
                                      const PopupMenuItem(
                                        value: 2,
                                        child: Text('Delete'),
                                      ),
                                    ],
                                    enabled: canManage,
                                    onSelected: (value) async {
                                      if (value == 1) {
                                        final edited = await context
                                            .pushNamed<bool>(
                                              'edit_post',
                                              pathParameters: {
                                                'postId': post.id.toString(),
                                              },
                                            );
                                        if (edited == true) {
                                          await fetchPosts(page: 1);
                                        }
                                      } else if (value == 2) {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete post?'),
                                            content: const Text(
                                              'This action cannot be undone.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  ctx,
                                                ).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          try {
                                            postProvider.deletePost(
                                              postId: post.id,
                                            );
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Post deleted successfully',
                                                ),
                                              ),
                                            );
                                            await fetchPosts(page: 1);
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Unable to delete post: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (posts.isNotEmpty || _currentPage > 1 || _hasMore)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_currentPage > 1)
                          OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => fetchPosts(page: _currentPage - 1),
                            child: const Text('Prev'),
                          ),
                        ..._visiblePageNumbers.map((page) {
                          final isActive = page == _currentPage;
                          return FilledButton(
                            onPressed: _isLoading || isActive
                                ? null
                                : () => fetchPosts(page: page),
                            style: isActive
                                ? FilledButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            child: Text(page.toString()),
                          );
                        }),
                        if (_hasMore)
                          OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => fetchPosts(page: _currentPage + 1),
                            child: const Text('Next'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
