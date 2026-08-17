import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/exam_seating_entities.dart';

class ExamPlanPdfService {
  const ExamPlanPdfService();

  Future<void> printPlan(DailyExamPlanEntity plan) async {
    final document = pw.Document();
    for (final room in plan.rooms) {
      final students =
          plan.studentAssignments
              .where((item) => item.roomId == room.id)
              .toList()
            ..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
      final teachers = plan.teacherAssignments
          .where((item) => item.roomId == room.id)
          .map((item) => item.teacherName)
          .join(', ');
      final classGroups = <String, List<StudentSeatAssignmentEntity>>{};
      for (final student in students) {
        classGroups
            .putIfAbsent('${student.classId}|${student.sectionId}', () => [])
            .add(student);
      }
      final groupedStudents = classGroups.values.toList()
        ..sort(
          (first, second) =>
              first.first.className.compareTo(second.first.className),
        );
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (_) => pw.Column(
            children: [
              pw.Text(
                plan.examName,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Room-wise Student Sitting List',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
            ],
          ),
          build: (_) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${room.name}  |  Capacity: ${room.capacity}'),
                pw.Text(
                  '${DateFormat('dd MMM yyyy').format(plan.examDate)}  |  ${plan.sessionLabel}',
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Invigilator(s): ${teachers.isEmpty ? '—' : teachers}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 6),
            for (final group in groupedStudents) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 3,
                ),
                color: PdfColors.grey300,
                child: pw.Text(
                  _classHeading(group.first.className),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Student Name',
                  'Father Name',
                  'Roll No.',
                  'Seat No.',
                ],
                data: group
                    .map(
                      (item) => [
                        item.studentName,
                        item.fatherName.isEmpty ? '—' : item.fatherName,
                        item.rollNumber,
                        '${item.seatNumber}',
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FixedColumnWidth(42),
                },
              ),
              pw.SizedBox(height: 5),
            ],
            pw.Text(
              'Total students: ${students.length}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      );
    }
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) {
          final duties = plan.teacherAssignments.toList()
            ..sort((a, b) => a.role.compareTo(b.role));
          return [
            pw.Text(
              '${plan.examName} — Teacher Duty Plan',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '${DateFormat('dd MMM yyyy').format(plan.examDate)}  |  ${plan.sessionLabel}',
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const ['Teacher', 'Assignment', 'Room'],
              data: duties
                  .map(
                    (item) => [
                      item.teacherName,
                      item.isRest
                          ? 'Rest'
                          : item.isPaperSupport
                          ? 'Paper Support'
                          : 'Invigilator',
                      item.roomName.isEmpty ? '—' : item.roomName,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          ];
        },
      ),
    );
    await Printing.layoutPdf(
      name: 'exam_plan_${DateFormat('yyyyMMdd').format(plan.examDate)}.pdf',
      onLayout: (_) => document.save(),
    );
  }

  String _classHeading(String value) {
    final name = value.trim();
    if (name.toLowerCase().startsWith('class ')) return name.toUpperCase();
    return 'CLASS ${name.toUpperCase()}';
  }
}
