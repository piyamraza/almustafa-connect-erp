import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/teacher_attendance_entity.dart';
import '../../domain/entities/teacher_entity.dart';
import '../../domain/repositories/teacher_attendance_repository.dart';
import '../../domain/repositories/teacher_repository.dart';

class TeacherAttendanceHistoryPage extends StatefulWidget {
  const TeacherAttendanceHistoryPage({super.key});
  @override State<TeacherAttendanceHistoryPage> createState() => _TeacherAttendanceHistoryPageState();
}

class _TeacherAttendanceHistoryPageState extends State<TeacherAttendanceHistoryPage> {
  late final Future<List<TeacherEntity>> _teachers = sl<TeacherRepository>().getTeachers();
  TeacherEntity? _teacher;
  DateTime _focusedDay = DateTime.now();
  DateTimeRange? _range;
  Future<List<TeacherAttendanceEntity>>? _history;

  void _load() {
    if (_teacher == null) return;
    final from = _range?.start ?? DateTime(_focusedDay.year, _focusedDay.month);
    final to = _range?.end ?? DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    setState(() => _history = sl<TeacherAttendanceRepository>().getByTeacher(_teacher!.id, from, to));
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: _range);
    if (range == null) return;
    setState(() => _range = range);
    _load();
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Teacher Attendance History')),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      FutureBuilder<List<TeacherEntity>>(future: _teachers, builder: (context, snapshot) => DropdownButtonFormField<TeacherEntity>(value: _teacher, isExpanded: true, decoration: const InputDecoration(labelText: 'Select teacher', border: OutlineInputBorder()), items: (snapshot.data ?? []).map((teacher) => DropdownMenuItem(value: teacher, child: Text('${teacher.fullName} (${teacher.employeeId})'))).toList(), onChanged: (value) { setState(() => _teacher = value); _load(); })),
      const SizedBox(height: 12), Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: _pickRange, icon: const Icon(Icons.date_range), label: Text(_range == null ? 'Current month' : '${_range!.start.day}/${_range!.start.month}/${_range!.start.year} - ${_range!.end.day}/${_range!.end.month}/${_range!.end.year}'))),
      const SizedBox(height: 12),
      Expanded(child: _history == null ? const Center(child: Text('Select a teacher to view attendance history.')) : FutureBuilder<List<TeacherAttendanceEntity>>(future: _history, builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); final records=snapshot.data!; final present=records.where((r)=>r.status==TeacherAttendanceStatus.present).length; final absent=records.where((r)=>r.status==TeacherAttendanceStatus.absent).length; final late=records.where((r)=>r.status==TeacherAttendanceStatus.late).length; final leave=records.where((r)=>r.status==TeacherAttendanceStatus.leave).length; final percentage=records.isEmpty?0:((present+late)/records.length)*100; return SingleChildScrollView(child: Column(children: [LayoutBuilder(builder:(context,c)=>GridView.count(crossAxisCount:c.maxWidth>700?5:2,childAspectRatio:1.8,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:8,mainAxisSpacing:8,children:[_metric('Present','$present',Colors.green),_metric('Absent','$absent',Colors.red),_metric('Late','$late',Colors.blue),_metric('Leave','$leave',Colors.orange),_metric('Attendance','${percentage.toStringAsFixed(1)}%',Colors.teal)])), const SizedBox(height:16), Card(child: Padding(padding:const EdgeInsets.all(12),child:TableCalendar<TeacherAttendanceEntity>(firstDay:DateTime(2020),lastDay:DateTime.now(),focusedDay:_focusedDay,eventLoader:(day)=>records.where((r)=>isSameDay(r.attendanceDate,day)).toList(),onPageChanged:(day)=>setState((){_focusedDay=day;_range=null;}) ))), const SizedBox(height:16), Card(child: records.isEmpty?const Padding(padding:EdgeInsets.all(24),child:Text('No attendance records for this period.')):ListView.separated(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:records.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(context,index){final record=records[index];return ListTile(title:Text('${record.attendanceDate.day}/${record.attendanceDate.month}/${record.attendanceDate.year}'),subtitle:record.remarks.isEmpty?null:Text(record.remarks),trailing:Chip(label:Text(record.status.name.toUpperCase())));}))])); }))
    ])),
  );
  Widget _metric(String label,String value,Color color)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(label),Text(value,style:TextStyle(color:color,fontWeight:FontWeight.bold,fontSize:20))])));
}
