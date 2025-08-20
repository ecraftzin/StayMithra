import 'user_model.dart';

class CampaignModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String mediaType; // 'image', 'video', 'mixed'
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? maxParticipants;
  final int currentParticipants;
  final double? price;
  final String? category;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? user; // For joined queries

  CampaignModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.mediaType = 'image',
    this.location,
    this.startDate,
    this.endDate,
    this.maxParticipants,
    this.currentParticipants = 0,
    this.price,
    this.category,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : [],
      videoUrls: json['video_urls'] != null
          ? List<String>.from(json['video_urls'] as List)
          : [],
      mediaType: json['media_type'] as String? ?? 'image',
      location: json['location'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      maxParticipants: json['max_participants'] as int?,
      currentParticipants: json['current_participants'] as int? ?? 0,
      price:
          json['price'] != null ? double.parse(json['price'].toString()) : null,
      category: json['category'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      sharesCount: json['shares_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      user: json['users'] != null ? UserModel.fromJson(json['users']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'image_urls': imageUrls,
      'location': location,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'price': price,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CampaignModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? imageUrls,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? maxParticipants,
    int? currentParticipants,
    double? price,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? user,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      price: price ?? this.price,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }
}
