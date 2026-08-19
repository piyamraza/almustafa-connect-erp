import 'package:flutter/material.dart';

import '../../../domain/entities/document_element_entity.dart';
import '../document_element_value_resolver.dart';
import '../document_render_context.dart';
import 'element_renderer.dart';

class ResultSubjectsTableRenderer extends ElementRenderer {
  const ResultSubjectsTableRenderer(this._valueResolver);

  final DocumentElementValueResolver _valueResolver;

  @override
  Widget render({
    required DocumentElementEntity element,
    required DocumentRenderContext context,
  }) {
    final value = _valueResolver.resolve(
      element: element,
      values: context.values,
    );
    final rows = value is List
        ? value
              .whereType<Map>()
              .map(
                (row) => row.map(
                  (key, value) =>
                      MapEntry(key.toString(), value?.toString() ?? ''),
                ),
              )
              .toList()
        : const <Map<String, String>>[];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .97),
        border: Border.all(color: const Color(0xFF163E68), width: 1.2),
        borderRadius: BorderRadius.circular(5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _ResultRow(
            values: [
              'SUBJECT',
              'PAPER / COMPONENTS',
              'TOTAL',
              'OBTAINED',
              '%',
              'GRADE',
              'REMARKS',
            ],
            header: true,
          ),
          if (rows.isEmpty)
            const Expanded(
              child: Center(child: Text('No subject marks available')),
            )
          else
            for (var index = 0; index < rows.length; index++)
              Expanded(
                child: _ResultRow(
                  values: [
                    rows[index]['subject'] ?? '',
                    rows[index]['components'] ?? '',
                    rows[index]['total'] ?? '',
                    rows[index]['obtained'] ?? '',
                    rows[index]['percentage'] ?? '',
                    rows[index]['grade'] ?? '',
                    rows[index]['remarks'] ?? '',
                  ],
                  shaded: index.isOdd,
                ),
              ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.values,
    this.header = false,
    this.shaded = false,
  });

  final List<String> values;
  final bool header;
  final bool shaded;
  static const _flex = [15, 29, 8, 10, 8, 8, 18];

  @override
  Widget build(BuildContext context) => Container(
    height: header ? 30 : null,
    color: header
        ? const Color(0xFF163E68)
        : shaded
        ? const Color(0xFFF2F6FA)
        : Colors.white.withValues(alpha: .96),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < values.length; index++)
          Expanded(
            flex: _flex[index],
            child: Container(
              alignment: index == 0 || index == 1 || index == 5
                  ? Alignment.centerLeft
                  : Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                border: Border(
                  right: index == values.length - 1
                      ? BorderSide.none
                      : BorderSide(
                          color: header
                              ? const Color(0x55FFFFFF)
                              : const Color(0xFFD2DCE7),
                        ),
                  bottom: header
                      ? BorderSide.none
                      : const BorderSide(color: Color(0xFFD2DCE7)),
                ),
              ),
              child: Text(
                values[index],
                maxLines: header ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                textAlign: index == 0 || index == 1 || index == 5
                    ? TextAlign.left
                    : TextAlign.center,
                style: TextStyle(
                  color: header ? Colors.white : const Color(0xFF23364D),
                  fontSize: header ? 8.5 : 9.5,
                  height: 1.12,
                  fontWeight: header ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
