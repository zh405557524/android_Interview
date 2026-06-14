import '../../enums/index.dart';

final class FeedbackParams {
  const FeedbackParams({
    required this.type,
    required this.content,
    this.contact,
    this.attachments = const <String>[],
  });

  final FeedbackType type;
  final String content;
  final String? contact;
  final List<String> attachments;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'content': content,
      if (contact != null && contact!.isNotEmpty) 'contact': contact,
      if (attachments.isNotEmpty) 'attachments': attachments,
    };
  }
}
