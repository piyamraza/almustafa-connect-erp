import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/entities/document_element_entity.dart';
import '../document_element_value_resolver.dart';
import '../document_render_context.dart';
import 'element_renderer.dart';

const _navy = Color(0xFF062E68);
const _blue = Color(0xFF0756B6);
const _gold = Color(0xFFD7A928);
const _ink = Color(0xFF102A56);

class ResultScoreBadgeRenderer extends ElementRenderer {
  const ResultScoreBadgeRenderer(this._resolver);
  final DocumentElementValueResolver _resolver;

  @override
  Widget render({
    required DocumentElementEntity element,
    required DocumentRenderContext context,
  }) {
    final data = _stringMap(
      _resolver.resolve(element: element, values: context.values),
    );
    return CustomPaint(
      painter: _BadgePainter(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '★  ★  ★',
            style: TextStyle(color: _gold, fontSize: 12, letterSpacing: 3),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: data['percentage'] ?? '0.0',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                      height: .95,
                    ),
                  ),
                  const TextSpan(
                    text: '%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Text(
            'OVERALL PERCENTAGE',
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_navy, _blue, _navy]),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'GRADE ${data['grade'] ?? '-'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 2);
    final radius = math.min(size.width, size.height) * .43;
    canvas.drawCircle(center, radius + 6, Paint()..color = _navy);
    canvas.drawCircle(center, radius + 3, Paint()..color = _gold);
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFB7CAE2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DevelopmentRatingsRenderer extends ElementRenderer {
  const DevelopmentRatingsRenderer(this._resolver);
  final DocumentElementValueResolver _resolver;

  @override
  Widget render({
    required DocumentElementEntity element,
    required DocumentRenderContext context,
  }) {
    final value = _resolver.resolve(element: element, values: context.values);
    final rows = value is List
        ? value.whereType<Map>().toList()
        : const <Map>[];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final raw in rows)
            Builder(
              builder: (_) {
                final row = _stringMap(raw);
                final rating = int.tryParse(row['rating'] ?? '') ?? 0;
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        row['label'] ?? '',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (rating <= 0)
                      const Text(
                        '—',
                        style: TextStyle(color: Color(0xFF98A2B3)),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (index) => Icon(
                            Icons.star_rounded,
                            size: 10.5,
                            color: index < rating
                                ? _navy
                                : const Color(0xFFD5DCE6),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class PerformanceChartRenderer extends ElementRenderer {
  const PerformanceChartRenderer(this._resolver);
  final DocumentElementValueResolver _resolver;

  @override
  Widget render({
    required DocumentElementEntity element,
    required DocumentRenderContext context,
  }) {
    final data = _stringMap(
      _resolver.resolve(element: element, values: context.values),
    );
    final rows = <(String, double, Color)>[
      ('Student', double.tryParse(data['student'] ?? '') ?? 0, _navy),
      if ((data['classAverage'] ?? '').isNotEmpty)
        (
          'Class Average',
          double.tryParse(data['classAverage']!) ?? 0,
          const Color(0xFFB8BDC5),
        ),
      if ((data['highest'] ?? '').isNotEmpty)
        ('Highest in Class', double.tryParse(data['highest']!) ?? 0, _gold),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final row in rows)
            Row(
              children: [
                SizedBox(
                  width: 68,
                  child: Text(
                    row.$1,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 7.5, color: _ink),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Stack(
                    children: [
                      Container(height: 17, color: const Color(0xFFF0F3F7)),
                      FractionallySizedBox(
                        widthFactor: (row.$2 / 100).clamp(0, 1),
                        child: Container(height: 17, color: row.$3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 35,
                  child: Text(
                    '${row.$2.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class TermProgressChartRenderer extends ElementRenderer {
  const TermProgressChartRenderer(this._resolver);
  final DocumentElementValueResolver _resolver;

  @override
  Widget render({
    required DocumentElementEntity element,
    required DocumentRenderContext context,
  }) {
    final value = _resolver.resolve(element: element, values: context.values);
    final rows = value is List
        ? value.whereType<Map>().map(_stringMap).toList()
        : const <Map<String, String>>[];
    return CustomPaint(painter: _ProgressPainter(rows));
  }
}

class ResultProfileDetailsRenderer extends ElementRenderer {
  const ResultProfileDetailsRenderer(this._resolver);
  final DocumentElementValueResolver _resolver;

  @override
  Widget render({
    required DocumentElementEntity element,
    required DocumentRenderContext context,
  }) {
    final data = _stringMap(
      _resolver.resolve(element: element, values: context.values),
    );
    Widget item(IconData icon, String label, String value, {Color? valueColor}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCCD9E8)),
            ),
            child: Icon(icon, size: 14, color: _navy),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 7, color: _ink)),
                const SizedBox(height: 1),
                Text(
                  value.trim().isEmpty ? '—' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    height: 1.05,
                    color: valueColor ?? _ink,
                    fontWeight: valueColor == null
                        ? FontWeight.w500
                        : FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['name'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 2, color: const Color(0xFFD6E0EC)),
        const SizedBox(height: 9),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    item(Icons.person_outline, 'FATHER / GUARDIAN', data['fatherName'] ?? ''),
                    item(Icons.badge_outlined, 'ADMISSION NO.', data['admissionNo'] ?? ''),
                    item(Icons.school_outlined, 'CLASS & SECTION', data['classSection'] ?? ''),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    item(Icons.access_time, 'ATTENDANCE', data['attendance'] ?? ''),
                    item(Icons.calendar_month_outlined, 'DATE OF BIRTH', data['dateOfBirth'] ?? ''),
                    Row(
                      children: [
                        Expanded(child: item(Icons.confirmation_number_outlined, 'ROLL NO.', data['rollNumber'] ?? '')),
                        Expanded(child: item(Icons.verified_outlined, 'RESULT STATUS', data['status'] ?? '', valueColor: const Color(0xFF16803B))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ResultSummaryStripRenderer extends ElementRenderer {
  const ResultSummaryStripRenderer(this._resolver);
  final DocumentElementValueResolver _resolver;

  @override
  Widget render({required DocumentElementEntity element, required DocumentRenderContext context}) {
    final data = _stringMap(_resolver.resolve(element: element, values: context.values));
    final entries = [
      ('TOTAL MARKS', '${data['obtained'] ?? '—'} / ${data['total'] ?? '—'}'),
      ('PERCENTAGE', '${data['percentage'] ?? '—'}%'),
      ('GRADE', data['grade'] ?? '—'),
      ('CLASS POSITION', data['classPosition'] ?? '—'),
      ('SECTION POSITION', data['sectionPosition'] ?? '—'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_navy, Color(0xFF0A4A96), _navy]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.emoji_events_rounded, size: 34, color: _gold),
          const SizedBox(width: 5),
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) Container(width: 1, height: 42, color: const Color(0x66FFFFFF)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(entries[index].$1, style: const TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(entries[index].$2, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class ResultRemarksPanelRenderer extends ElementRenderer {
  const ResultRemarksPanelRenderer(this._resolver);
  final DocumentElementValueResolver _resolver;

  @override
  Widget render({required DocumentElementEntity element, required DocumentRenderContext context}) {
    final raw = _resolver.resolve(element: element, values: context.values)?.toString() ?? '';
    final teacher = element.metadata['kind'] == 'teacher';
    final title = teacher ? 'CLASS TEACHER REMARKS' : 'GENERAL REMARKS';
    final lines = raw.replaceAll('•', '').split('\n').where((line) => line.trim().isNotEmpty).toList();
    const generalIcons = [Icons.school_outlined, Icons.access_time, Icons.menu_book_outlined];
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7), border: Border.all(color: const Color(0xFFC7D6E7))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          children: [
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4), color: _navy, child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 8, 13, 7),
                child: teacher
                    ? Stack(
                        children: [
                          const Positioned(left: 0, top: -4, child: Text('“', style: TextStyle(fontSize: 30, color: _navy, fontWeight: FontWeight.w900, height: 1))),
                          Padding(padding: const EdgeInsets.only(left: 22, right: 15), child: Text(raw, maxLines: 5, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 7.8, height: 1.35, color: _ink))),
                          const Positioned(right: 0, bottom: 0, child: Icon(Icons.draw_outlined, size: 20, color: _navy)),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var i = 0; i < lines.length && i < 3; i++)
                            Row(children: [
                              Container(width: 23, height: 23, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFC7D6E7))), child: Icon(generalIcons[i], size: 13, color: _navy)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(lines[i].trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 7.5, color: _ink))),
                            ]),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SchoolMottoBadgeRenderer extends ElementRenderer {
  const SchoolMottoBadgeRenderer();

  @override
  Widget render({required DocumentElementEntity element, required DocumentRenderContext context}) {
    return CustomPaint(
      painter: _ShieldPainter(),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(11, 13, 11, 17),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('A Tradition of\nExcellence in\nEducation', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 7.2, height: 1.15)),
          SizedBox(height: 3),
          Icon(Icons.menu_book_rounded, color: Color(0xFFF5E4AD), size: 16),
        ]),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width - 3, size.height * .18)
      ..lineTo(size.width - 6, size.height * .68)
      ..quadraticBezierTo(size.width * .78, size.height * .9, size.width / 2, size.height)
      ..quadraticBezierTo(size.width * .22, size.height * .9, 6, size.height * .68)
      ..lineTo(3, size.height * .18)
      ..close();
    canvas.drawPath(path, Paint()..color = _navy);
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = _gold);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter(this.rows);
  final List<Map<String, String>> rows;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty) return;
    const left = 20.0;
    final bottom = size.height - 22;
    final top = 18.0;
    final usableWidth = size.width - left * 2;
    final points = <Offset>[];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < rows.length; i++) {
      final value = (double.tryParse(rows[i]['value'] ?? '') ?? 0).clamp(
        0,
        100,
      );
      final x = rows.length == 1
          ? size.width / 2
          : left + usableWidth * i / (rows.length - 1);
      final y = bottom - (bottom - top) * value / 100;
      points.add(Offset(x, y));
    }
    canvas.drawLine(
      Offset(left, bottom),
      Offset(size.width - left, bottom),
      Paint()..color = const Color(0xFFB8C7D9),
    );
    if (points.length > 1) {
      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = _blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, Paint()..color = _blue);
      final value = double.tryParse(rows[i]['value'] ?? '') ?? 0;
      textPainter.text = TextSpan(
        text: '${value.toStringAsFixed(0)}%',
        style: const TextStyle(
          fontSize: 8,
          color: _ink,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 16),
      );
      textPainter.text = TextSpan(
        text: rows[i]['label'] ?? '',
        style: const TextStyle(fontSize: 7, color: _ink),
      );
      textPainter.layout(maxWidth: 70);
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, bottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) =>
      oldDelegate.rows != rows;
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return value.map(
    (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
  );
}
