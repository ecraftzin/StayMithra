import 'post_model.dart';
import 'campaign_model.dart';

enum FeedItemType { post, campaign }

class FeedItem {
  final FeedItemType type;
  final PostModel? post;
  final CampaignModel? campaign;
  final DateTime createdAt;

  FeedItem({
    required this.type,
    this.post,
    this.campaign,
    required this.createdAt,
  });

  factory FeedItem.fromPost(PostModel post) {
    return FeedItem(
      type: FeedItemType.post,
      post: post,
      createdAt: post.createdAt,
    );
  }

  factory FeedItem.fromCampaign(CampaignModel campaign) {
    return FeedItem(
      type: FeedItemType.campaign,
      campaign: campaign,
      createdAt: campaign.createdAt,
    );
  }

  String get id {
    switch (type) {
      case FeedItemType.post:
        return post!.id;
      case FeedItemType.campaign:
        return campaign!.id;
    }
  }

  String get userId {
    switch (type) {
      case FeedItemType.post:
        return post!.userId;
      case FeedItemType.campaign:
        return campaign!.userId;
    }
  }

  String get content {
    switch (type) {
      case FeedItemType.post:
        return post!.content;
      case FeedItemType.campaign:
        return campaign!.description;
    }
  }

  String? get title {
    switch (type) {
      case FeedItemType.post:
        return null;
      case FeedItemType.campaign:
        return campaign!.title;
    }
  }

  List<String> get imageUrls {
    switch (type) {
      case FeedItemType.post:
        return post!.imageUrls;
      case FeedItemType.campaign:
        return campaign!.imageUrls;
    }
  }

  List<String> get videoUrls {
    switch (type) {
      case FeedItemType.post:
        return post!.videoUrls;
      case FeedItemType.campaign:
        return campaign!.videoUrls;
    }
  }

  String get mediaType {
    switch (type) {
      case FeedItemType.post:
        return post!.mediaType;
      case FeedItemType.campaign:
        return campaign!.mediaType;
    }
  }

  String? get location {
    switch (type) {
      case FeedItemType.post:
        return post!.location;
      case FeedItemType.campaign:
        return campaign!.location;
    }
  }

  dynamic get user {
    switch (type) {
      case FeedItemType.post:
        return post!.user;
      case FeedItemType.campaign:
        return campaign!.user;
    }
  }
}
