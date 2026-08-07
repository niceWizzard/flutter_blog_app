import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blog_app/data/post.dart';
import 'package:flutter_blog_app/providers/post_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? post;
  List<PostComment> comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchPost();
    });
  }

  Future<void> fetchPost() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final postId = int.parse(widget.postId);
      await postProvider.incrementPostViews(postId: postId);
      final fetchedPost = await postProvider.getPostById(postId);
      final fetchedComments = await postProvider.getCommentsForPost(postId);

      if (!mounted) return;

      setState(() {
        post = fetchedPost;
        comments = fetchedComments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching post: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Builder(
            builder: (context) {
              final postProvider = context.read<PostProvider>();
              final canManage =
                  post != null &&
                  postProvider.canManagePost(
                    post: post!,
                    currentUserId: postProvider.currentUserId,
                  );

              if (!canManage) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<int>(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 1, child: Text('Edit')),
                  const PopupMenuItem(value: 2, child: Text('Delete')),
                ],
                onSelected: (value) async {
                  if (value == 1 && post != null) {
                    final edited = await context.pushNamed<bool>(
                      'edit_post',
                      pathParameters: {'postId': post!.id.toString()},
                    );
                    if (edited == true) {
                      await fetchPost();
                    }
                  } else if (value == 2 && post != null) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete post?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await postProvider.deletePost(postId: post!.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Post deleted successfully'),
                            ),
                          );
                          context.pop();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Unable to delete post: $e'),
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                enabled: canManage,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : post != null
          ? ContentWithPost(
              post: post!,
              comments: comments,
              onCommentAdded: fetchPost,
            )
          : Center(child: Text('Post with id ${widget.postId} not found')),
    );
  }
}

class ContentWithPost extends StatefulWidget {
  const ContentWithPost({
    super.key,
    required this.post,
    required this.comments,
    required this.onCommentAdded,
  });

  final Post post;
  final List<PostComment> comments;
  final Future<void> Function() onCommentAdded;

  @override
  State<ContentWithPost> createState() => _ContentWithPostState();
}

class _ContentWithPostState extends State<ContentWithPost> {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedCommentImage;
  bool _isSubmittingComment = false;
  int? _editingCommentId;
  String? _editingCommentImageUrl;
  bool _removeCommentImage = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference < const Duration(minutes: 1)) {
      return 'just now';
    }
    if (difference < const Duration(hours: 1)) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    if (difference < const Duration(days: 1)) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference < const Duration(days: 2)) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final formattedHour = hour.toString().padLeft(2, '0');
    final formattedMinute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';

    return '${local.day} ${monthNames[local.month - 1]} ${local.year} '
        '$formattedHour:$formattedMinute$period';
  }

  Future<void> _pickCommentImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedCommentImage = picked;
        _removeCommentImage = false;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_isSubmittingComment) {
      return;
    }

    final content = _commentController.text.trim();
    final hasImage =
        _selectedCommentImage != null ||
        (_editingCommentImageUrl != null && !_removeCommentImage);

    if (content.isEmpty && !hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some text or an image.')),
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final postProvider = context.read<PostProvider>();
      if (_editingCommentId != null) {
        await postProvider.updateComment(
          commentId: _editingCommentId!,
          postId: widget.post.id,
          content: content,
          imageUrl: _editingCommentImageUrl,
          removeImage: _removeCommentImage,
          newImage: _selectedCommentImage,
        );
        _editingCommentId = null;
        _editingCommentImageUrl = null;
        _removeCommentImage = false;
      } else {
        await postProvider.addComment(
          postId: widget.post.id,
          content: content,
          image: _selectedCommentImage,
        );
      }

      _commentController.clear();
      setState(() {
        _selectedCommentImage = null;
        _removeCommentImage = false;
      });
      await widget.onCommentAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to save comment: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.post.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.post.imageUrls.first,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.article,
                    size: 64,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              widget.post.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Created ${_formatDate(widget.post.createdAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.update, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Updated ${_formatDate(widget.post.updatedAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _statsChip(
                  Icons.comment_outlined,
                  '${widget.post.commentsCount} comments',
                ),
                _statsChip(
                  Icons.remove_red_eye_outlined,
                  '${widget.post.viewsCount} views',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.post.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (widget.post.imageUrls.length > 1) ...[
              const SizedBox(height: 24),
              Text(
                'Other images',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.post.imageUrls.length - 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final imageUrl = widget.post.imageUrls[index + 1];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 140,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, _) => Container(
                          width: 140,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Comments',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _commentController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Write a comment...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickCommentImage,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Add image'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _submitComment,
                          icon: _isSubmittingComment
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _isSubmittingComment
                                ? (_editingCommentId != null
                                      ? 'Saving...'
                                      : 'Posting...')
                                : (_editingCommentId != null
                                      ? 'Save comment'
                                      : 'Post comment'),
                          ),
                        ),
                      ],
                    ),
                    if (_editingCommentId != null &&
                        _editingCommentImageUrl != null &&
                        _selectedCommentImage == null &&
                        !_removeCommentImage) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _editingCommentImageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, _, __) => Container(
                            height: 120,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _removeCommentImage = true;
                                _selectedCommentImage = null;
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove image'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _pickCommentImage,
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Replace image'),
                          ),
                        ],
                      ),
                    ],
                    if (_selectedCommentImage != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedCommentImage!.path),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedCommentImage = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel image'),
                          ),
                        ],
                      ),
                    ],
                    if (_editingCommentId != null &&
                        _removeCommentImage &&
                        _selectedCommentImage == null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Existing image will be removed',
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _pickCommentImage,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('New'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.comments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No comments yet. Be the first to comment.'),
              )
            else
              ...widget.comments.map(
                (comment) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  comment.commenterName.isNotEmpty
                                      ? comment.commenterName
                                      : comment.userId,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (comment.userId ==
                                  context.read<PostProvider>().currentUserId)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Colors.blueAccent,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _editingCommentId = comment.id;
                                          _commentController.text =
                                              comment.content;
                                          _editingCommentImageUrl =
                                              comment.imageUrl;
                                          _selectedCommentImage = null;
                                          _removeCommentImage = false;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                              'Delete comment?',
                                            ),
                                            content: const Text(
                                              'This comment will be removed permanently.',
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

                                        if (confirmed != true) {
                                          return;
                                        }

                                        try {
                                          await context
                                              .read<PostProvider>()
                                              .deleteComment(
                                                commentId: comment.id,
                                                postId: widget.post.id,
                                              );
                                          if (mounted) {
                                            await widget.onCommentAdded();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Comment deleted successfully.',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Unable to delete comment: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              Text(
                                _formatDate(comment.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (comment.content.isNotEmpty) Text(comment.content),
                          if (comment.imageUrl != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                comment.imageUrl!,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.scaleDown,
                                errorBuilder: (context, _, _) => Container(
                                  height: 160,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statsChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
