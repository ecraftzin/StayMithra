import 'package:flutter/material.dart';
import 'package:staymitra/models/post_model.dart';
import 'package:staymitra/services/post_service.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/Comments/comments_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  bool _isLiked = false;
  bool _isLiking = false;
  int _currentLikeCount = 0;

  @override
  void initState() {
    super.initState();
    _currentLikeCount = widget.post.likesCount;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      try {
        final liked = await _postService.hasUserLikedPost(
            widget.post.id, currentUser.id);
        if (mounted) {
          setState(() => _isLiked = liked);
        }
      } catch (e) {
        print('Error checking like status: $e');
      }
    }
  }

  Future<void> _toggleLike() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || _isLiking) return;

    if (mounted) {
      setState(() => _isLiking = true);
    }

    try {
      int newLikeCount;
      if (_isLiked) {
        newLikeCount = await _postService.unlikePost(
            widget.post.id, currentUser.id);
      } else {
        newLikeCount = await _postService.likePost(
            widget.post.id, currentUser.id);
      }

      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _currentLikeCount = newLikeCount;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  void _handleComment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(
          contentId: widget.post.id,
          contentType: 'post',
          contentTitle: widget.post.content,
        ),
      ),
    );
  }

  void _handleShare() async {
    try {
      final String shareText = 'Check out this post: ${widget.post.content}';
      final String shareUrl = 'https://staymitra.app/post/${widget.post.id}';
      await Share.share('$shareText\n\n$shareUrl');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: screenWidth * 0.06,
                  backgroundImage: widget.post.user?.avatarUrl != null
                      ? CachedNetworkImageProvider(widget.post.user!.avatarUrl!)
                      : null,
                  child: widget.post.user?.avatarUrl == null
                      ? Icon(Icons.person, size: screenWidth * 0.06)
                      : null,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.user?.fullName ?? widget.post.user?.username ?? 'Unknown User',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.post.location ?? 'Unknown location',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.04),

            // Post content
            Text(
              widget.post.content ?? '',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                height: 1.4,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),

            // Post images
            if (widget.post.imageUrls.isNotEmpty) ...[
              SizedBox(
                height: screenWidth * 0.8,
                child: PageView.builder(
                  itemCount: widget.post.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(right: screenWidth * 0.02),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        child: CachedNetworkImage(
                          imageUrl: widget.post.imageUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
            ],

            // Action buttons
            Row(
              children: [
                // Like button
                IconButton(
                  onPressed: _toggleLike,
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey[600],
                    size: screenWidth * 0.07,
                  ),
                ),
                Text(
                  '$_currentLikeCount',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),

                // Comment button
                IconButton(
                  onPressed: _handleComment,
                  icon: Icon(
                    Icons.comment_outlined,
                    color: Colors.grey[600],
                    size: screenWidth * 0.07,
                  ),
                ),
                Text(
                  '${widget.post.commentsCount}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),

                // Share button
                IconButton(
                  onPressed: _handleShare,
                  icon: Icon(
                    Icons.share_outlined,
                    color: Colors.grey[600],
                    size: screenWidth * 0.07,
                  ),
                ),
              ],
            ),

            SizedBox(height: screenWidth * 0.04),

            // Post metadata
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posted on ${_formatDate(widget.post.createdAt)}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (widget.post.location != null) ...[
                    SizedBox(height: screenWidth * 0.02),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: screenWidth * 0.04, color: Colors.grey[600]),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          widget.post.location!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
