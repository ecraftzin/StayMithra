import 'package:flutter/material.dart';
import 'package:staymitra/services/campaign_service.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/models/campaign_model.dart';
import 'package:staymitra/Campaigns/create_campaign_page.dart';
// import 'package:staymitra/Campaigns/campaign_detail_page.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';

class CampaignsPage extends StatefulWidget {
  const CampaignsPage({super.key});

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage> {
  final CampaignService _campaignService = CampaignService();
  final AuthService _authService = AuthService();
  List<CampaignModel> _campaigns = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _campaignsPerPage = 10;
  RealtimeChannel? _campaignsSubscription;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
    _subscribeToNewCampaigns();
  }

  @override
  void dispose() {
    _campaignsSubscription?.unsubscribe();
    super.dispose();
  }

  void _subscribeToNewCampaigns() {
    _campaignsSubscription =
        _campaignService.subscribeToNewCampaigns((newCampaign) {
      if (mounted) {
        setState(() {
          _campaigns.insert(0, newCampaign);
        });
      }
    });
  }

  Future<void> _loadCampaigns({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _campaigns.clear();
      });
    }

    try {
      final campaigns = await _campaignService.getAllCampaigns(
        limit: _campaignsPerPage,
        offset: _currentPage * _campaignsPerPage,
      );

      setState(() {
        if (refresh) {
          _campaigns = campaigns;
        } else {
          _campaigns.addAll(campaigns);
        }
        _currentPage++;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading campaigns: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreCampaigns() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    await _loadCampaigns();
  }

  Future<void> _navigateToCreateCampaign() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateCampaignPage()),
    );

    if (result == true) {
      _loadCampaigns(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Campaigns & Events',
          style: TextStyle(
            color: const Color(0xFF007F8C),
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _navigateToCreateCampaign,
            icon: const Icon(
              Icons.add,
              color: Color(0xFF007F8C),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadCampaigns(refresh: true),
              child: _campaigns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event,
                            size: screenWidth * 0.2,
                            color: Colors.grey,
                          ),
                          SizedBox(height: screenWidth * 0.04),
                          Text(
                            'No campaigns yet',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          ElevatedButton(
                            onPressed: _navigateToCreateCampaign,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007F8C),
                            ),
                            child: const Text(
                              'Create your first campaign',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      itemCount: _campaigns.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _campaigns.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final campaign = _campaigns[index];
                        return CampaignCard(
                          campaign: campaign,
                          screenWidth: screenWidth,
                          onTap: () {
                            // TODO: Navigate to campaign detail page
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Campaign: ${campaign.title}')),
                            );
                          },
                          onLoadMore: index == _campaigns.length - 3
                              ? _loadMoreCampaigns
                              : null,
                        );
                      },
                    ),
            ),
    );
  }
}

class CampaignCard extends StatefulWidget {
  final CampaignModel campaign;
  final double screenWidth;
  final VoidCallback onTap;
  final VoidCallback? onLoadMore;

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.screenWidth,
    required this.onTap,
    this.onLoadMore,
  });

  @override
  State<CampaignCard> createState() => _CampaignCardState();
}

class _CampaignCardState extends State<CampaignCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoadMore?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    final user = campaign.user;
    final screenWidth = widget.screenWidth;

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.05,
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            (user?.username ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? user?.username ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          timeago.format(campaign.createdAt),
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (campaign.category != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenWidth * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007F8C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Text(
                        campaign.category!,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: const Color(0xFF007F8C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Campaign image (only show if valid Supabase URL)
            if (campaign.imageUrls.isNotEmpty &&
                campaign.imageUrls.any((url) =>
                    url.startsWith('https://rssnqbqbrejnjeiukrdr.supabase.co')))
              SizedBox(
                height: screenWidth * 0.5,
                width: double.infinity,
                child: Image.network(
                  campaign.imageUrls.firstWhere((url) => url
                      .startsWith('https://rssnqbqbrejnjeiukrdr.supabase.co')),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: screenWidth * 0.5,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print(
                        'Error loading campaign image: ${campaign.imageUrls.first}');
                    return Container(
                      height: screenWidth * 0.5,
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, size: 50),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Campaign details
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Text(
                    campaign.description,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenWidth * 0.02),

                  // Location and participants
                  Row(
                    children: [
                      if (campaign.location != null) ...[
                        Icon(
                          Icons.location_on,
                          size: screenWidth * 0.04,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Expanded(
                          child: Text(
                            campaign.location!,
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.people,
                        size: screenWidth * 0.04,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        '${campaign.currentParticipants}${campaign.maxParticipants != null ? '/${campaign.maxParticipants}' : ''}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  // Price and date
                  if (campaign.price != null || campaign.startDate != null)
                    SizedBox(height: screenWidth * 0.02),

                  Row(
                    children: [
                      if (campaign.price != null) ...[
                        Icon(
                          Icons.currency_rupee,
                          size: screenWidth * 0.04,
                          color: const Color(0xFF007F8C),
                        ),
                        Text(
                          campaign.price!.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: const Color(0xFF007F8C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (campaign.startDate != null) ...[
                        Icon(
                          Icons.schedule,
                          size: screenWidth * 0.04,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          '${campaign.startDate!.day}/${campaign.startDate!.month}/${campaign.startDate!.year}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
