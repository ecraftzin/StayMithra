import 'user_model.dart';

class CommentModel {
  final String id;
  final String userId;
  final String postId;
  final String? campaignId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? user;

  CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    this.campaignId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      postId:
          json['post_id'] as String? ?? json['campaign_id'] as String? ?? '',
      campaignId: json['campaign_id'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : json['users'] != null
              ? UserModel.fromJson(json['users'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'campaign_id': campaignId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CommentModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? campaignId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? user,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      campaignId: campaignId ?? this.campaignId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CommentModel(id: $id, userId: $userId, content: $content)';
  }
}
