import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/story_comment.dart';

class CommentRepository {
  final ApiClient _api;

  const CommentRepository(this._api);

  Future<List<StoryComment>> fetchByStory(String storyId) async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.comments(storyId),
    );
    final list = data['data'] as List? ?? [];
    return list
        .map((item) => StoryComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StoryComment> create(String storyId, String content) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.comments(storyId),
      data: {'content': content},
    );
    return StoryComment.fromJson(data);
  }

  Future<void> like(String commentId) async {
    await _api.post<dynamic>(ApiEndpoints.likeComment(commentId));
  }

  Future<void> unlike(String commentId) async {
    await _api.delete<dynamic>(ApiEndpoints.unlikeComment(commentId));
  }
}
