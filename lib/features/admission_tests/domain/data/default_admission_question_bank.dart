import '../entities/admission_test_entities.dart';

List<AdmissionQuestionEntity> defaultAdmissionQuestionBank() {
  final result = <AdmissionQuestionEntity>[];
  void addLevel(String level, String subject, List<_Spec> specs) {
    for (var index = 0; index < specs.length; index++) {
      final spec = specs[index];
      result.add(
        AdmissionQuestionEntity(
          id: 'default_${_key(level)}_${_key(subject)}_${index + 1}',
          classLevel: level,
          subject: subject,
          type: spec.type,
          difficulty: spec.difficulty,
          prompt: spec.prompt,
          marks: spec.marks,
          correctAnswer: spec.answer,
          options: spec.options,
          createdAt: DateTime(2026),
          isDefault: true,
        ),
      );
    }
  }

  addLevel('Nursery', 'Oral & Observation', _nursery(false));
  addLevel('KG', 'Oral & Observation', _nursery(true));
  for (var grade = 1; grade <= 2; grade++) {
    final level = 'Class $grade';
    addLevel(level, 'English', _english(grade));
    addLevel(level, 'Urdu', _urdu(grade));
    addLevel(level, 'Mathematics', _mathematics(grade));
    addLevel(level, 'General Knowledge', _generalKnowledge(grade));
  }
  for (var grade = 3; grade <= 5; grade++) {
    final level = 'Class $grade';
    addLevel(level, 'English', _english(grade));
    addLevel(level, 'Urdu', _urdu(grade));
    addLevel(level, 'Mathematics', _mathematics(grade));
    addLevel(level, 'Science / GK', _science(grade));
  }
  for (var grade = 6; grade <= 8; grade++) {
    final level = 'Class $grade';
    addLevel(level, 'English', _english(grade));
    addLevel(level, 'Urdu', _urdu(grade));
    addLevel(level, 'Mathematics', _mathematics(grade));
    addLevel(level, 'Science', _science(grade));
    addLevel(level, 'Reasoning', _reasoning(grade));
  }
  return List.unmodifiable(result);
}

List<_Spec> _nursery(bool kg) => [
  _easy(
    'Tell the teacher your full name.',
    'Teacher observation',
    AdmissionQuestionType.oral,
  ),
  _easy(
    'Identify the colours red, blue and green.',
    'Correctly identifies the colours',
    AdmissionQuestionType.observation,
  ),
  _easy(
    'Name the circle, square and triangle.',
    'Correctly names the shapes',
    AdmissionQuestionType.observation,
  ),
  _medium(
    'Count aloud from 1 to ${kg ? 20 : 10}.',
    'Counts in the correct order',
    AdmissionQuestionType.oral,
  ),
  _medium(
    'Recognize the letters ${kg ? 'A to Z' : 'A, B, C, D and E'}.',
    'Correctly recognizes the letters',
    AdmissionQuestionType.observation,
  ),
  _medium(
    'Hold a pencil and trace a straight and curved line.',
    'Uses an age-appropriate pencil grip',
    AdmissionQuestionType.observation,
  ),
  _difficult(
    'Follow a two-step instruction given by the teacher.',
    'Completes both steps in order',
    AdmissionQuestionType.observation,
  ),
  _difficult(
    'Look at a picture and describe what is happening.',
    'Communicates a relevant observation',
    AdmissionQuestionType.oral,
  ),
  _easy(
    'Name two common fruits.',
    'Any two correct fruits',
    AdmissionQuestionType.oral,
  ),
  _medium(
    'Match two identical pictures or objects.',
    'Correctly matches the pair',
    AdmissionQuestionType.observation,
  ),
  _easy(
    'Identify big and small objects.',
    'Correctly distinguishes size',
    AdmissionQuestionType.observation,
  ),
  _difficult(
    'Complete a simple three-piece picture pattern.',
    'Completes the pattern independently',
    AdmissionQuestionType.observation,
  ),
];

List<_Spec> _english(int grade) {
  final noun = grade <= 2
      ? 'book'
      : grade <= 5
      ? 'teacher'
      : 'knowledge';
  return [
    _easy(
      'Choose the correct plural of "book".',
      'books',
      AdmissionQuestionType.multipleChoice,
      options: ['bookes', 'books', 'book'],
    ),
    _easy(
      'Choose the opposite of "happy".',
      'sad',
      AdmissionQuestionType.multipleChoice,
      options: ['kind', 'sad', 'fast'],
    ),
    _easy(
      'Fill in the blank: The sun ___ in the east.',
      'rises',
      AdmissionQuestionType.fillBlank,
    ),
    _medium(
      'Identify the noun in this sentence: Ali reads a book.',
      'Ali / book',
      AdmissionQuestionType.shortAnswer,
    ),
    _medium(
      'Change this sentence into the past tense: She walks to school.',
      'She walked to school.',
      AdmissionQuestionType.shortAnswer,
    ),
    _medium(
      'Use the word "$noun" in a meaningful sentence.',
      'Any grammatically correct sentence',
      AdmissionQuestionType.shortAnswer,
      marks: 2,
    ),
    _difficult(
      'Correct the sentence: He do not likes apples.',
      'He does not like apples.',
      AdmissionQuestionType.shortAnswer,
      marks: 2,
    ),
    _difficult(
      'Write ${grade <= 3 ? 'three' : 'five'} sentences about your school.',
      'Relevant, organized and grammatically correct response',
      AdmissionQuestionType.shortAnswer,
      marks: 3,
    ),
    _difficult(
      'Read and answer: Sara watered the plant every day. Why did the plant grow well?',
      'Because Sara watered it every day.',
      AdmissionQuestionType.shortAnswer,
      marks: 2,
    ),
  ];
}

List<_Spec> _urdu(int grade) => [
  _easy(
    'لفظ "کتاب" کی جمع لکھیں۔',
    'کتابیں',
    AdmissionQuestionType.shortAnswer,
  ),
  _easy(
    'لفظ "بڑا" کی ضد منتخب کریں۔',
    'چھوٹا',
    AdmissionQuestionType.multipleChoice,
    options: ['اونچا', 'چھوٹا', 'موٹا'],
  ),
  _easy(
    'خالی جگہ پُر کریں: سورج مشرق سے ___ ہوتا ہے۔',
    'طلوع',
    AdmissionQuestionType.fillBlank,
  ),
  _medium(
    'جملے میں اسم پہچانیں: علی اسکول جاتا ہے۔',
    'علی / اسکول',
    AdmissionQuestionType.shortAnswer,
  ),
  _medium(
    'لفظ "خوشی" کو ایک جملے میں استعمال کریں۔',
    'کوئی درست اور بامعنی جملہ',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
  _medium(
    'درست املا لکھیں: زمہ داری',
    'ذمہ داری',
    AdmissionQuestionType.shortAnswer,
  ),
  _difficult(
    'جملہ درست کریں: بچے میدان میں کھیلتا ہے۔',
    'بچے میدان میں کھیلتے ہیں۔',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
  _difficult(
    'اپنے اسکول کے بارے میں ${grade <= 3 ? 'تین' : 'پانچ'} جملے لکھیں۔',
    'متعلقہ اور درست جملے',
    AdmissionQuestionType.shortAnswer,
    marks: 3,
  ),
  _difficult(
    'محنت کامیابی کی کنجی کیوں ہے؟ مختصر جواب دیں۔',
    'محنت سے انسان اپنے مقصد حاصل کرتا ہے۔',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
];

List<_Spec> _mathematics(int grade) {
  final base = grade * 10;
  final multiplier = grade <= 2
      ? 2
      : grade <= 5
      ? 4
      : 7;
  return [
    _easy(
      'Calculate: $base + ${grade + 4}',
      '${base + grade + 4}',
      AdmissionQuestionType.shortAnswer,
    ),
    _easy(
      'Calculate: ${base + 9} - ${grade + 2}',
      '${base + 7 - grade}',
      AdmissionQuestionType.shortAnswer,
    ),
    _easy(
      'What is $multiplier × ${grade + 2}?',
      '${multiplier * (grade + 2)}',
      AdmissionQuestionType.shortAnswer,
    ),
    _medium(
      'Complete the pattern: $grade, ${grade + 2}, ${grade + 4}, ___',
      '${grade + 6}',
      AdmissionQuestionType.fillBlank,
    ),
    _medium(
      'A box has ${base + 5} pencils. ${grade + 3} are used. How many remain?',
      '${base + 2 - grade}',
      AdmissionQuestionType.shortAnswer,
      marks: 2,
    ),
    _medium(
      'What is half of ${base * 2}?',
      '$base',
      AdmissionQuestionType.shortAnswer,
    ),
    _difficult(
      'A class has ${base + 12} students arranged equally in ${grade <= 2 ? 2 : 4} rows. How many students are in each row?',
      '${(base + 12) / (grade <= 2 ? 2 : 4)}',
      AdmissionQuestionType.shortAnswer,
      marks: 2,
    ),
    _difficult(
      'Find the missing number: ${multiplier} × ___ = ${multiplier * (grade + 5)}',
      '${grade + 5}',
      AdmissionQuestionType.fillBlank,
      marks: 2,
    ),
    _difficult(
      grade <= 3
          ? 'A rectangle has length 6 cm and width 3 cm. Find its perimeter.'
          : 'A rectangle has length ${grade + 5} cm and width ${grade + 1} cm. Find its area.',
      grade <= 3 ? '18 cm' : '${(grade + 5) * (grade + 1)} cm²',
      AdmissionQuestionType.shortAnswer,
      marks: 3,
    ),
  ];
}

List<_Spec> _generalKnowledge(int grade) => [
  _easy(
    'What is the name of our country?',
    'Pakistan',
    AdmissionQuestionType.shortAnswer,
  ),
  _easy(
    'How many days are there in a week?',
    '7',
    AdmissionQuestionType.shortAnswer,
  ),
  _easy(
    'Which animal is known as the king of the jungle?',
    'Lion',
    AdmissionQuestionType.multipleChoice,
    options: ['Lion', 'Goat', 'Rabbit'],
  ),
  _medium(
    'Name the capital city of Pakistan.',
    'Islamabad',
    AdmissionQuestionType.shortAnswer,
  ),
  _medium(
    'Which organ helps us to breathe?',
    'Lungs',
    AdmissionQuestionType.multipleChoice,
    options: ['Heart', 'Lungs', 'Stomach'],
  ),
  _medium(
    'Why do plants need sunlight?',
    'To make food / grow',
    AdmissionQuestionType.shortAnswer,
  ),
  _difficult(
    'Name the four main directions.',
    'North, South, East and West',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
  _difficult(
    'State one way to keep the environment clean.',
    'Any valid cleanliness practice',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
  _difficult(
    'Why is clean drinking water important?',
    'It keeps us healthy and prevents disease',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
];

List<_Spec> _science(int grade) => [
  _easy(
    'Which part of a plant absorbs water from the soil?',
    'Roots',
    AdmissionQuestionType.multipleChoice,
    options: ['Flower', 'Roots', 'Fruit'],
  ),
  _easy(
    'What gas do humans need for breathing?',
    'Oxygen',
    AdmissionQuestionType.shortAnswer,
  ),
  _easy(
    'Name the planet on which we live.',
    'Earth',
    AdmissionQuestionType.shortAnswer,
  ),
  _medium(
    'Explain one difference between a solid and a liquid.',
    'A solid has a fixed shape; a liquid takes the shape of its container.',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
  _medium(
    'What is the function of the heart?',
    'It pumps blood around the body.',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
  _medium(
    'Why are green plants called producers?',
    'They make their own food by photosynthesis.',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
  _difficult(
    grade <= 5
        ? 'Describe the water cycle in three steps.'
        : 'Explain how evaporation and condensation are involved in the water cycle.',
    'Evaporation, condensation and precipitation/collection.',
    AdmissionQuestionType.shortAnswer,
    marks: 3,
  ),
  _difficult(
    'What happens to particles when a substance is heated?',
    'They gain energy and move faster/farther apart.',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
  _difficult(
    grade <= 5
        ? 'Why does a shadow form?'
        : 'Differentiate between a conductor and an insulator with one example each.',
    grade <= 5
        ? 'An opaque object blocks light.'
        : 'A conductor allows heat/electricity to pass; an insulator resists it.',
    AdmissionQuestionType.shortAnswer,
    marks: 3,
  ),
];

List<_Spec> _reasoning(int grade) => [
  _easy(
    'Find the next number: 2, 4, 6, 8, ___',
    '10',
    AdmissionQuestionType.fillBlank,
  ),
  _easy(
    'Which one is different: triangle, square, circle, mango?',
    'mango',
    AdmissionQuestionType.multipleChoice,
    options: ['triangle', 'circle', 'mango'],
  ),
  _easy(
    'If all cats are animals, is every cat an animal?',
    'Yes',
    AdmissionQuestionType.trueFalse,
  ),
  _medium(
    'Complete the analogy: Bird is to sky as fish is to ___.',
    'water',
    AdmissionQuestionType.fillBlank,
  ),
  _medium(
    'Find the missing number: 3, 6, 12, 24, ___',
    '48',
    AdmissionQuestionType.fillBlank,
  ),
  _medium(
    'Ali is taller than Bilal. Bilal is taller than Hamza. Who is the shortest?',
    'Hamza',
    AdmissionQuestionType.shortAnswer,
  ),
  _difficult(
    'A clock shows 3:00. What angle is formed between the hour and minute hands?',
    '90 degrees',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
  _difficult(
    'If yesterday was Monday, what day will it be three days after tomorrow?',
    'Saturday',
    AdmissionQuestionType.shortAnswer,
    marks: 2,
  ),
  _difficult(
    'Find the rule and next term: 1, 4, 9, 16, ___',
    '25',
    AdmissionQuestionType.fillBlank,
    marks: 2,
  ),
];

_Spec _easy(
  String p,
  String a,
  AdmissionQuestionType t, {
  List<String> options = const [],
  double marks = 1,
}) => _Spec(p, a, t, AdmissionQuestionDifficulty.easy, options, marks);
_Spec _medium(
  String p,
  String a,
  AdmissionQuestionType t, {
  List<String> options = const [],
  double marks = 1,
}) => _Spec(p, a, t, AdmissionQuestionDifficulty.medium, options, marks);
_Spec _difficult(
  String p,
  String a,
  AdmissionQuestionType t, {
  List<String> options = const [],
  double marks = 1,
}) => _Spec(p, a, t, AdmissionQuestionDifficulty.difficult, options, marks);
String _key(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

class _Spec {
  const _Spec(
    this.prompt,
    this.answer,
    this.type,
    this.difficulty,
    this.options,
    this.marks,
  );
  final String prompt, answer;
  final AdmissionQuestionType type;
  final AdmissionQuestionDifficulty difficulty;
  final List<String> options;
  final double marks;
}
