import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'attendance_calendar_page.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/attendance_entity.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() =>
      _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState
    extends State<AttendanceHistoryPage> {
  @override
  void initState() {
    super.initState();
  }
  //------------------------------------------------------------
  // Controllers
  //------------------------------------------------------------

  final TextEditingController _searchController =
      TextEditingController();

  //------------------------------------------------------------
  // Filters
  //------------------------------------------------------------

  DateTime _selectedDate = DateTime.now();

  String? _selectedClass;

  String? _selectedSection;
bool get _isChoosingClass => _selectedClass == null;
  //------------------------------------------------------------
  // Static Lists
  //------------------------------------------------------------

  final List<String> _classes = const [
    'Nursery',
    'Prep',
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
  ];

  final List<String> _sections = const [
    'A',
    'B',
    'C',
    'D',
  ];

  //------------------------------------------------------------
  // Lifecycle
  //------------------------------------------------------------

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  //------------------------------------------------------------
  // Pick Date
  //------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }
Future<void> _showSectionPicker(String className) async {
  final section = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Select Section'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _sections
            .map(
              (item) => ListTile(
                leading: const Icon(Icons.class_outlined),
                title: Text('Section $item'),
                onTap: () => Navigator.pop(dialogContext, item),
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  if (section == null) return;

  setState(() {
  _selectedClass = className;
  _selectedSection = section;
});
}

  //------------------------------------------------------------
  // Build
  //------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
  create: (_) => sl<AttendanceBloc>()
    ..add(const LoadAttendanceEvent()),
  child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance History',
        ),
      ),
      body: Padding(
  padding: const EdgeInsets.all(24),
  child: _isChoosingClass
      ? GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 5,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 3.2,
  ),
  itemCount: _classes.length,
  itemBuilder: (context, index) {
    return Card(
      child: InkWell(
        onTap: () {
  if (_sections.length > 1) {
    _showSectionPicker(_classes[index]);
  } else {
    setState(() {
      _selectedClass = _classes[index];
      _selectedSection = _sections.first;
    });
  }
},
        child: Center(
          child: Text(
            _classes[index],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  },
)
      : Column(
          children: [
            //--------------------------------------------------
            // Filters
            //--------------------------------------------------

            

            //--------------------------------------------------
            // Search
            //--------------------------------------------------

            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText:
                    'Search by student name or admission number',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            //--------------------------------------------------
            // Attendance History List
            //--------------------------------------------------
Text(
  '${_selectedClass!}${_selectedSection == null ? '' : ' • Section $_selectedSection'}',
  style: Theme.of(context).textTheme.headlineSmall,
),
const SizedBox(height: 12),

const SizedBox(height: 12),

Expanded(
  child: AttendanceCalendarPage(
    classId: _selectedClass!,
    sectionId: _selectedSection,
  ),
),
                          
          ],
        ),
      ),
    ),
   );
  }
}