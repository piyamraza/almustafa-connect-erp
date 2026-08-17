import 'package:almustafa_connect_erp/features/documents/domain/entities/appreciation_certificate_entity.dart';
import 'package:almustafa_connect_erp/features/documents/presentation/bloc/appreciation_certificate_bloc.dart';
import 'package:almustafa_connect_erp/features/settings/domain/entities/school_settings_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('next serial continues the current-year appreciation sequence', () {
    final year = DateTime.now().year;
    final state = AppreciationCertificateLoaded(
      students: const [],
      classes: const [],
      sections: const [],
      settings: _settings(),
      history: [
        _certificate('APP-$year-0002'),
        _certificate('APP-${year - 1}-0099'),
        _certificate('APP-$year-0007'),
      ],
    );
    expect(state.nextSerial, 'APP-$year-0008');
  });

  test('custom and standard categories have readable labels', () {
    expect(AppreciationCategory.excellentProject.label, 'Excellent Project');
    expect(AppreciationTheme.blueGold.label, 'Blue Gold');
  });
}

AppreciationCertificateEntity _certificate(String serial) =>
    AppreciationCertificateEntity(
      id: serial,
      serialNumber: serial,
      studentId: 'student',
      studentName: 'Student',
      admissionNumber: 'ADM-1',
      rollNumber: '1',
      className: 'Class 5',
      sectionName: 'A',
      category: AppreciationCategory.excellentProject,
      categoryLabel: 'Excellent Project',
      title: 'Certificate of Appreciation',
      description: 'Achievement',
      achievementDate: DateTime(2026),
      issueDate: DateTime(2026),
      teacherName: '',
      principalName: '',
      theme: AppreciationTheme.blueGold,
      issuedAt: DateTime(2026),
    );

SchoolSettingsEntity _settings() => SchoolSettingsEntity(
  id: 'school',
  schoolName: 'School',
  schoolCode: 'SCH',
  currentSession: '2026-27',
  sessionStartDate: DateTime(2026),
  sessionEndDate: DateTime(2027),
  currency: 'PKR',
  currencySymbol: 'Rs',
  dateFormat: 'dd MMM yyyy',
  timeFormat: '12h',
  admissionPrefix: 'ADM',
  rollNumberPrefix: 'ROLL',
  receiptPrefix: 'REC',
  updatedAt: DateTime(2026),
);
