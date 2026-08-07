import '../entities/engagement_person_entity.dart';

class BirthdayResolverService {
  const BirthdayResolverService();

  bool isBirthdayOn(EngagementPersonEntity person, DateTime date) {
    return person.dateOfBirth.month == date.month &&
        person.dateOfBirth.day == date.day;
  }

  List<EngagementPersonEntity> birthdaysOn(
    List<EngagementPersonEntity> people,
    DateTime date,
  ) {
    final result = people
        .where((person) => person.isActive && isBirthdayOn(person, date))
        .toList();

    result.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );

    return result;
  }

  List<EngagementPersonEntity> birthdaysToday(
    List<EngagementPersonEntity> people, {
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();

    return birthdaysOn(people, currentDate);
  }

  List<EngagementPersonEntity> birthdaysTomorrow(
    List<EngagementPersonEntity> people, {
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();

    final tomorrow = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day + 1,
    );

    return birthdaysOn(people, tomorrow);
  }

  List<EngagementPersonEntity> birthdaysBetween(
    List<EngagementPersonEntity> people, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    if (end.isBefore(start)) {
      return const [];
    }

    final result = people.where((person) {
      if (!person.isActive) {
        return false;
      }

      final nextBirthday = nextBirthdayDate(person, fromDate: start);

      return !nextBirthday.isBefore(start) && !nextBirthday.isAfter(end);
    }).toList();

    result.sort((a, b) {
      final aBirthday = nextBirthdayDate(a, fromDate: start);

      final bBirthday = nextBirthdayDate(b, fromDate: start);

      final dateComparison = aBirthday.compareTo(bBirthday);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return result;
  }

  List<EngagementPersonEntity> birthdaysThisWeek(
    List<EngagementPersonEntity> people, {
    DateTime? now,
  }) {
    final currentDate = _dateOnly(now ?? DateTime.now());

    final endOfWeek = currentDate.add(
      Duration(days: DateTime.daysPerWeek - currentDate.weekday),
    );

    return birthdaysBetween(people, startDate: currentDate, endDate: endOfWeek);
  }

  List<EngagementPersonEntity> birthdaysThisMonth(
    List<EngagementPersonEntity> people, {
    DateTime? now,
  }) {
    final currentDate = _dateOnly(now ?? DateTime.now());

    final endOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0);

    return birthdaysBetween(
      people,
      startDate: currentDate,
      endDate: endOfMonth,
    );
  }

  DateTime nextBirthdayDate(
    EngagementPersonEntity person, {
    DateTime? fromDate,
  }) {
    final currentDate = _dateOnly(fromDate ?? DateTime.now());

    var birthday = _birthdayForYear(person.dateOfBirth, currentDate.year);

    if (birthday.isBefore(currentDate)) {
      birthday = _birthdayForYear(person.dateOfBirth, currentDate.year + 1);
    }

    return birthday;
  }

  int daysUntilBirthday(EngagementPersonEntity person, {DateTime? fromDate}) {
    final currentDate = _dateOnly(fromDate ?? DateTime.now());

    final birthday = nextBirthdayDate(person, fromDate: currentDate);

    return birthday.difference(currentDate).inDays;
  }

  DateTime _birthdayForYear(DateTime dateOfBirth, int year) {
    if (dateOfBirth.month == DateTime.february &&
        dateOfBirth.day == 29 &&
        !_isLeapYear(year)) {
      return DateTime(year, DateTime.february, 28);
    }

    return DateTime(year, dateOfBirth.month, dateOfBirth.day);
  }

  bool _isLeapYear(int year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
