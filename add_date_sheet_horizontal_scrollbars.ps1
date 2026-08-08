$ErrorActionPreference = "Stop"

$root = "D:\Projects\almustafa-connect-erp"
$manualPath = Join-Path $root "lib\features\exams\presentation\pages\manual_exam_date_sheet_builder_page.dart"
$autoPath = Join-Path $root "lib\features\exams\presentation\pages\auto_exam_date_sheet_generator_page.dart"

function Backup-Once([string]$path) {
  $bak = "$path.before_horizontal_scrollbar.bak"
  if (-not (Test-Path $bak)) { Copy-Item $path $bak }
}

function Replace-Once([string]$text,[string]$old,[string]$new,[string]$label) {
  if (-not $text.Contains($old)) { throw "Patch failed: pattern not found for $label" }
  Write-Host "Applied: $label" -ForegroundColor Green
  return $text.Replace($old,$new)
}

Backup-Once $manualPath
$manual = (Get-Content $manualPath -Raw) -replace "`r`n","`n"

if (-not $manual.Contains("final _tableScrollbarController = ScrollController();")) {
  $manual = Replace-Once $manual @'
  final _tableHeaderController = ScrollController();
  final _tableBodyController = ScrollController();
'@ @'
  final _tableHeaderController = ScrollController();
  final _tableBodyController = ScrollController();
  final _tableScrollbarController = ScrollController();
'@ "manual scrollbar controller"
}

if (-not $manual.Contains("_tableScrollbarController.addListener(_syncScrollbarToBody);")) {
  $manual = Replace-Once $manual @'
    _tableHeaderController.addListener(_syncHeaderToBody);
    _tableBodyController.addListener(_syncBodyToHeader);
'@ @'
    _tableHeaderController.addListener(_syncHeaderToBody);
    _tableBodyController.addListener(_syncBodyToHeader);
    _tableScrollbarController.addListener(_syncScrollbarToBody);
'@ "manual scrollbar listener"
}

if (-not $manual.Contains("_tableScrollbarController.dispose();")) {
  $manual = Replace-Once $manual @'
    _tableHeaderController.dispose();
    _tableBodyController.dispose();
'@ @'
    _tableHeaderController.dispose();
    _tableBodyController.dispose();
    _tableScrollbarController.dispose();
'@ "manual scrollbar dispose"
}

if (-not $manual.Contains("void _syncScrollbarToBody()")) {
  $manual = Replace-Once $manual @'
  void _syncBodyToHeader() =>
      _syncHorizontalScroll(_tableBodyController, _tableHeaderController);

  void _syncHorizontalScroll(ScrollController source, ScrollController target) {
'@ @'
  void _syncBodyToHeader() {
    _syncHorizontalScroll(_tableBodyController, _tableHeaderController);
    _syncHorizontalScroll(_tableBodyController, _tableScrollbarController);
  }

  void _syncScrollbarToBody() {
    _syncHorizontalScroll(_tableScrollbarController, _tableBodyController);
    _syncHorizontalScroll(_tableScrollbarController, _tableHeaderController);
  }

  void _syncHorizontalScroll(ScrollController source, ScrollController target) {
'@ "manual scroll synchronization"
}

if (-not $manual.Contains("controller: _tableScrollbarController,")) {
$old = @'
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _tableBodyController,
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: _matrixTableWidth,
                                      child: ListView.builder(
                                        itemCount: _matrixDates.length,
                                        itemBuilder: (context, index) =>
                                            _buildMatrixBodyRow(
                                              _matrixDates[index],
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
'@
$new = @'
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _tableBodyController,
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: _matrixTableWidth,
                                      child: ListView.builder(
                                        itemCount: _matrixDates.length,
                                        itemBuilder: (context, index) =>
                                            _buildMatrixBodyRow(
                                              _matrixDates[index],
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 18,
                                  child: Scrollbar(
                                    controller: _tableScrollbarController,
                                    thumbVisibility: true,
                                    trackVisibility: true,
                                    scrollbarOrientation:
                                        ScrollbarOrientation.bottom,
                                    child: SingleChildScrollView(
                                      controller: _tableScrollbarController,
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: _matrixTableWidth,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
'@
  $manual = Replace-Once $manual $old $new "manual visible horizontal scrollbar"
}

[IO.File]::WriteAllText($manualPath,($manual -replace "`n","`r`n"),[Text.UTF8Encoding]::new($false))

Backup-Once $autoPath
$auto = (Get-Content $autoPath -Raw) -replace "`r`n","`n"

if (-not $auto.Contains("class _AutoDateSheetPreviewTable extends StatefulWidget")) {
  $start = $auto.IndexOf("class _AutoDateSheetPreviewTable extends StatelessWidget")
  if ($start -lt 0) { throw "Patch failed: auto preview class not found" }

  $box = $auto.IndexOf("  Widget _box(", $start)
  if ($box -lt 0) { throw "Patch failed: auto _box method not found" }

  $prefix = $auto.Substring(0,$start)
  $tail = $auto.Substring($box)

  $head = @'
class _AutoDateSheetPreviewTable extends StatefulWidget {
  const _AutoDateSheetPreviewTable({required this.matrix});

  final _DateSheetMatrix matrix;

  @override
  State<_AutoDateSheetPreviewTable> createState() =>
      _AutoDateSheetPreviewTableState();
}

class _AutoDateSheetPreviewTableState
    extends State<_AutoDateSheetPreviewTable> {
  static const double _dateWidth = 112;
  static const double _classWidth = 112;

  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matrix = widget.matrix;
    final width = _dateWidth + matrix.columns.length * _classWidth;

    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        trackVisibility: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: Column(
              children: [
                Container(
                  height: 44,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      _box(
                        context,
                        width: _dateWidth,
                        child: const Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (final column in matrix.columns)
                        _box(
                          context,
                          width: _classWidth,
                          child: Text(
                            column.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: matrix.dates.length,
                    itemBuilder: (context, index) {
                      final date = matrix.dates[index];
                      return SizedBox(
                        height: 56,
                        child: Row(
                          children: [
                            _box(
                              context,
                              width: _dateWidth,
                              child: Text(
                                '${_AutoExamDateSheetGeneratorViewState._date(date)}\n'
                                '${_AutoExamDateSheetGeneratorViewState._fullDayName(date.weekday)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            for (final column in matrix.columns)
                              _box(
                                context,
                                width: _classWidth,
                                child: Text(
                                  matrix.subjectsFor(date, column),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

'@
  $auto = $prefix + $head + $tail
  Write-Host "Applied: auto preview visible horizontal scrollbar" -ForegroundColor Green
}

[IO.File]::WriteAllText($autoPath,($auto -replace "`n","`r`n"),[Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "DONE - Manual + Auto horizontal scrollbars patched." -ForegroundColor Cyan
Write-Host ""
Write-Host "Now run:" -ForegroundColor Yellow
Write-Host "dart format lib/features/exams/presentation/pages/manual_exam_date_sheet_builder_page.dart lib/features/exams/presentation/pages/auto_exam_date_sheet_generator_page.dart"
Write-Host "flutter analyze lib/features/exams/presentation/pages/manual_exam_date_sheet_builder_page.dart lib/features/exams/presentation/pages/auto_exam_date_sheet_generator_page.dart"
