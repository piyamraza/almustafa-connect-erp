abstract class PushTopicService {
  Future<void> subscribe(String topic);
  Future<void> unsubscribe(String topic);
}

class CommunicationTopics {
  const CommunicationTopics._();

  static const String wholeSchool = 'whole_school';
  static const String teachers = 'teachers';
  static const String parents = 'parents';
  static const String students = 'students';
  static const String staff = 'staff';

  static String classTopic(String classId) => 'class_${_sanitize(classId)}';

  static String sectionTopic(String classId, String sectionId) =>
      'class_${_sanitize(classId)}_section_${_sanitize(sectionId)}';

  static String _sanitize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }
}
