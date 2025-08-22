import 'package:flutter/material.dart';
import 'package:staymitra/models/campaign_model.dart';
import 'package:staymitra/services/campaign_service.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/Comments/comments_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CampaignDetailPage extends StatefulWidget {
  final CampaignModel campaign;

  const CampaignDetailPage({super.key, required this.campaign});

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  final CampaignService _campaignService = CampaignService();
  final AuthService _authService = AuthService();
  bool _isLiked = false;
  bool _isLiking = false;
  int _currentLikeCount = 0;

  @override
  void initState() {
    super.initState();
    _currentLikeCount = widget.campaign.likesCount ?? 0;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      try {
        final liked = await _campaignService.hasUserLikedCampaign(
            widget.campaign.id, currentUser.id);
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
        newLikeCount = await _campaignService.unlikeCampaign(
            widget.campaign.id, currentUser.id);
      } else {
        newLikeCount = await _campaignService.likeCampaign(
            widget.campaign.id, currentUser.id);
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
          contentId: widget.campaign.id,
          contentType: 'campaign',
          contentTitle: widget.campaign.title,
        ),
      ),
    );
  }

  void _handleShare() async {
    try {
      final String shareText =
          'Join this campaign: ${widget.campaign.title} - ${widget.campaign.description}';
      final String shareUrl =
          'https://staymitra.app/campaign/${widget.campaign.id}';
      await Share.share('$shareText\n\n$shareUrl');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  void _openMap() async {
    if (widget.campaign.location != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.campaign.location!)}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open map')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Details'),
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
                  backgroundImage: widget.campaign.user?.avatarUrl != null
                      ? CachedNetworkImageProvider(
                          widget.campaign.user!.avatarUrl!)
                      : null,
                  child: widget.campaign.user?.avatarUrl == null
                      ? Icon(Icons.person, size: screenWidth * 0.06)
                      : null,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.campaign.user?.fullName ??
                            widget.campaign.user?.username ??
                            'Unknown User',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.campaign.location ?? 'Unknown location',
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

            // Campaign title
            Text(
              widget.campaign.title,
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),

            // Campaign category
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenWidth * 0.01,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF007F8C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Text(
                widget.campaign.category ?? 'Unknown',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: const Color(0xFF007F8C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),

            // Campaign description
            Text(
              widget.campaign.description,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                height: 1.4,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),

            // Campaign images
            if (widget.campaign.imageUrls.isNotEmpty) ...[
              SizedBox(
                height: screenWidth * 0.8,
                child: PageView.builder(
                  itemCount: widget.campaign.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(right: screenWidth * 0.02),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        child: CachedNetworkImage(
                          imageUrl: widget.campaign.imageUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                                child: CircularProgressIndicator()),
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

            // Campaign details
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: screenWidth * 0.04, color: Colors.grey[600]),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        '${widget.campaign.startDate != null ? _formatDate(widget.campaign.startDate!) : 'TBD'} - ${widget.campaign.endDate != null ? _formatDate(widget.campaign.endDate!) : 'TBD'}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.02),

                  // Location with map button
                  if (widget.campaign.location != null) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: screenWidth * 0.04, color: Colors.grey[600]),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            widget.campaign.location!,
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openMap,
                          child: const Text('View Map'),
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.02),
                  ],

                  // Price
                  if (widget.campaign.price != null) ...[
                    Row(
                      children: [
                        Icon(Icons.currency_rupee,
                            size: screenWidth * 0.04,
                            color: const Color(0xFF007F8C)),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          '₹${widget.campaign.price!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: const Color(0xFF007F8C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.02),
                  ],

                  // Participants
                  Row(
                    children: [
                      Icon(Icons.people,
                          size: screenWidth * 0.04, color: Colors.grey[600]),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        '${widget.campaign.currentParticipants ?? 0}${widget.campaign.maxParticipants != null ? '/${widget.campaign.maxParticipants}' : ''} participants',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.04),

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
                  '${widget.campaign.commentsCount ?? 0}',
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
