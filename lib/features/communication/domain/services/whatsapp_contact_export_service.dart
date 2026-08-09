import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import '../../../../core/contact/contact_number_helper.dart';
import '../../../students/domain/entities/student_entity.dart';

class WhatsAppExportContact {
  const WhatsAppExportContact({
    required this.studentId,
    required this.displayName,
    required this.phoneNumber,
  });

  final String studentId;
  final String displayName;
  final String phoneNumber;
}

class WhatsAppContactExportResult {
  const WhatsAppContactExportResult({
    required this.filesCreated,
    required this.uniqueContacts,
    required this.duplicatesRemoved,
    required this.missingNumbers,
  });

  final int filesCreated;
  final int uniqueContacts;
  final int duplicatesRemoved;
  final int missingNumbers;
}

class WhatsAppContactExportService {
  const WhatsAppContactExportService();

  List<WhatsAppExportContact> contactsFromStudents(
    Iterable<StudentEntity> students,
  ) {
    return students
        .map(
          (student) => WhatsAppExportContact(
            studentId: student.id,
            displayName:
                '${student.fullName} - ${student.preferredWhatsAppContactName}',
            phoneNumber: student.preferredWhatsAppNumber,
          ),
        )
        .toList(growable: false);
  }

  Future<WhatsAppContactExportResult> exportVCardBatches({
    required Iterable<WhatsAppExportContact> contacts,
    required String filePrefix,
    int batchSize = 250,
  }) async {
    if (batchSize <= 0) throw ArgumentError.value(batchSize, 'batchSize');

    final unique = <String, WhatsAppExportContact>{};
    var missing = 0;
    var duplicates = 0;

    for (final contact in contacts) {
      final phone = _internationalPhone(contact.phoneNumber);
      if (phone.length < 10) {
        missing++;
        continue;
      }
      if (unique.containsKey(phone)) {
        duplicates++;
        continue;
      }
      unique[phone] = WhatsAppExportContact(
        studentId: contact.studentId,
        displayName: contact.displayName,
        phoneNumber: phone,
      );
    }

    if (unique.isEmpty) {
      return WhatsAppContactExportResult(
        filesCreated: 0,
        uniqueContacts: 0,
        duplicatesRemoved: duplicates,
        missingNumbers: missing,
      );
    }

    final values = unique.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final files = <XFile>[];
    for (var start = 0; start < values.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, values.length);
      final batch = values.sublist(start, end);
      final batchNumber = (start ~/ batchSize) + 1;
      final content = batch.map(_vCard).join();
      files.add(
        XFile.fromData(
          Uint8List.fromList(utf8.encode(content)),
          mimeType: 'text/vcard',
          name: '${_safeName(filePrefix)}_${batchNumber.toString().padLeft(2, '0')}.vcf',
        ),
      );
    }

    Share.downloadFallbackEnabled = true;
    await Share.shareXFiles(
      files,
      subject: '$filePrefix WhatsApp contacts',
      text: 'Import these contacts, then create matching broadcast lists in WhatsApp.',
    );

    return WhatsAppContactExportResult(
      filesCreated: files.length,
      uniqueContacts: values.length,
      duplicatesRemoved: duplicates,
      missingNumbers: missing,
    );
  }

  String _internationalPhone(String value) {
    var phone = ContactNumberHelper.normalizeNumber(value).replaceAll('+', '');
    if (phone.startsWith('00')) phone = phone.substring(2);
    if (phone.startsWith('0') && phone.length == 11) {
      phone = '92${phone.substring(1)}';
    }
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _vCard(WhatsAppExportContact contact) {
    final name = _escape(contact.displayName);
    return 'BEGIN:VCARD\r\n'
        'VERSION:3.0\r\n'
        'FN:$name\r\n'
        'N:$name;;;;\r\n'
        'TEL;TYPE=CELL:+${contact.phoneNumber}\r\n'
        'NOTE:Al-Mustafa ERP WhatsApp broadcast contact\r\n'
        'END:VCARD\r\n';
  }

  String _escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\n', r'\n');

  String _safeName(String value) => value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
}
