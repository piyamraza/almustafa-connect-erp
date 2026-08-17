import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../data/teacher_appointment_letter_service.dart';
import '../services/appointment_letter_pdf_service.dart';

class TeacherAppointmentLettersPage extends StatefulWidget {
  const TeacherAppointmentLettersPage({super.key, this.initialTeacher});
  final TeacherEntity? initialTeacher;
  @override
  State<TeacherAppointmentLettersPage> createState() => _TeacherAppointmentLettersPageState();
}

class _TeacherAppointmentLettersPageState extends State<TeacherAppointmentLettersPage> {
  late final TeacherAppointmentLetterService service;
  @override
  void initState() {
    super.initState();
    service = TeacherAppointmentLetterService(sl<FirebaseFirestore>(), sl<FirebaseStorage>());
    if (widget.initialTeacher != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final teacher = widget.initialTeacher!;
        _openForm(existing: {
          'teacherId': teacher.id,
          'teacherName': teacher.fullName,
          'employeeId': teacher.employeeId,
          'fatherName': teacher.fatherName,
          'cnic': teacher.cnic,
          'designation': teacher.designation,
          'monthlySalary': teacher.monthlySalary.toStringAsFixed(0),
          'joiningDate': Timestamp.fromDate(teacher.joiningDate),
          'status': 'Draft',
          'version': 1,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Teacher Appointment Letters'), actions: [IconButton(tooltip: 'Terms templates', onPressed: _editTemplates, icon: const Icon(Icons.rule_rounded)), const DashboardNavigationButton()]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('New Letter')),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.watchLetters(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        if (items.isEmpty) return const Center(child: Text('No appointment letters yet. Create the first letter.'));
        return LayoutBuilder(builder: (context, c) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: c.maxWidth >= 1000 ? 3 : c.maxWidth >= 650 ? 2 : 1, mainAxisExtent: 190, crossAxisSpacing: 14, mainAxisSpacing: 14),
          itemCount: items.length,
          itemBuilder: (_, i) => _card(items[i]),
        ));
      },
    ),
  );

  Widget _card(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'Draft';
    final color = <String, Color>{
          'Signed': Colors.green,
          'Issued': Colors.blue,
          'Rejected': Colors.red,
          'Expired': Colors.orange,
        }[status] ??
        Colors.blueGrey;

    return Card(
      child: InkWell(
        onTap: () => _preview(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['teacherName']?.toString() ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(status),
                    side: BorderSide(color: color),
                    labelStyle: TextStyle(color: color),
                  ),
                ],
              ),
              Text(
                '${item['designation'] ?? '-'} • '
                '${item['employmentType'] ?? '-'}',
              ),
              const SizedBox(height: 8),
              Text(
                '${item['letterNumber'] ?? '-'} • '
                'Version ${item['version'] ?? 1}',
              ),
              const Spacer(),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _preview(item),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Preview'),
                  ),
                  const Spacer(),
                  if (status == 'Draft')
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _openForm(existing: item),
                      icon: const Icon(Icons.edit_outlined),
                    )
                  else
                    IconButton(
                      tooltip: 'Create revision',
                      onPressed: () => _openForm(
                        existing: {
                          ...item,
                          'id': service.newId(),
                          'letterNumber': service.generateNumber(),
                          'version': (item['version'] ?? 1) + 1,
                          'status': 'Draft',
                          'unsignedPdfUrl': '',
                          'signedDocumentUrl': '',
                        },
                      ),
                      icon: const Icon(Icons.copy_all_outlined),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => _AppointmentLetterForm(service: service, existing: existing)));
    if (changed == true && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment letter draft saved.')));
  }

  void _preview(Map<String, dynamic> item) => Navigator.push(context, MaterialPageRoute(builder: (_) => _AppointmentLetterPreview(service: service, letter: item)));

  Future<void> _editTemplates() async {
    final terms = await service.loadTerms();
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (_) => _TermsDialog(service: service, terms: terms));
  }
}

class _AppointmentLetterForm extends StatefulWidget {
  const _AppointmentLetterForm({required this.service, this.existing});
  final TeacherAppointmentLetterService service;
  final Map<String, dynamic>? existing;
  @override State<_AppointmentLetterForm> createState() => _AppointmentLetterFormState();
}

class _AppointmentLetterFormState extends State<_AppointmentLetterForm> {
  final key = GlobalKey<FormState>();
  late Future<List<TeacherEntity>> teachers;
  late Future<List<Map<String, dynamic>>> termsFuture;
  TeacherEntity? selected;
  late final Map<String, TextEditingController> c;
  String employment = 'Permanent'; DateTime issue = DateTime.now(), joining = DateTime.now(), start = DateTime.now(), end = DateTime.now().add(const Duration(days: 365)); bool witnesses = false;
  List<Map<String, dynamic>> terms = [];
  @override void initState() { super.initState(); final e = widget.existing ?? {}; teachers = sl<TeacherRepository>().getTeachers(); termsFuture = widget.service.loadTerms(); employment = e['employmentType'] ?? 'Permanent'; witnesses = e['witnessesRequired'] == true; issue = _date(e['issueDate'], issue); joining = _date(e['joiningDate'], joining); start = _date(e['startDate'], start); end = _date(e['endDate'], end); c = {for (final k in ['fatherName','cnic','designation','branch','assignment','monthlySalary','allowancesDeductions','workingTimings','reportingAuthority','remarks']) k: TextEditingController(text: '${e[k] ?? ''}')}; }
  DateTime _date(dynamic v, DateTime fallback) => v is Timestamp ? v.toDate() : v is DateTime ? v : fallback;
  @override void dispose() { for (final x in c.values) { x.dispose(); } super.dispose(); }
  InputDecoration _d(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder());
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.existing == null ? 'New Appointment Letter' : 'Edit Draft')), body: FutureBuilder<List<Map<String, dynamic>>>(future: termsFuture, builder: (_, ts) { if (!ts.hasData) return const Center(child: CircularProgressIndicator()); if (terms.isEmpty) terms = widget.existing?['terms'] is List ? (widget.existing!['terms'] as List).map((e) => Map<String,dynamic>.from(e)).toList() : ts.data!; return FutureBuilder<List<TeacherEntity>>(future: teachers, builder: (_, s) { if (!s.hasData) return const Center(child: CircularProgressIndicator()); return Form(key: key, child: ListView(padding: const EdgeInsets.all(16), children: [
    DropdownButtonFormField<String>(decoration: _d('Teacher'), value: selected?.id ?? widget.existing?['teacherId'], items: s.data!.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.fullName} • ${t.employeeId}'))).toList(), onChanged: (id) { selected = s.data!.firstWhere((t) => t.id == id); setState(() { c['fatherName']!.text=selected!.fatherName;c['cnic']!.text=selected!.cnic;c['designation']!.text=selected!.designation;c['monthlySalary']!.text=selected!.monthlySalary.toStringAsFixed(0); joining=selected!.joiningDate; }); }, validator: (v) => v == null ? 'Select teacher' : null),
    const SizedBox(height: 12), Wrap(spacing: 12, runSpacing: 12, children: c.entries.map((e) => SizedBox(width: MediaQuery.sizeOf(context).width < 700 ? double.infinity : 360, child: TextFormField(controller: e.value, decoration: _d({'fatherName':'Father / Husband Name','cnic':'CNIC','designation':'Designation','branch':'Campus / Branch','assignment':'Assigned Subjects / Classes','monthlySalary':'Monthly Salary','allowancesDeductions':'Allowances & Deductions','workingTimings':'Working Days & Timings','reportingAuthority':'Reporting Authority','remarks':'Remarks'}[e.key]!)))).toList()),
    const SizedBox(height: 12), DropdownButtonFormField(value: employment, decoration: _d('Employment Type'), items: ['Permanent','Probation','Contract','Part-time'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(), onChanged:(v)=>setState(()=>employment=v!)),
    const SizedBox(height: 12), Wrap(spacing: 10, children: [_dateButton('Issue', issue, (v)=>issue=v), _dateButton('Joining', joining, (v)=>joining=v), if (employment != 'Permanent') _dateButton('Start', start, (v)=>start=v), if (employment != 'Permanent') _dateButton('End', end, (v)=>end=v)]),
    SwitchListTile(value: witnesses, onChanged:(v)=>setState(()=>witnesses=v), title: const Text('Include witness signatures')),
    const Divider(), const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), ...terms.asMap().entries.map((e)=>CheckboxListTile(value:e.value['enabled'] != false, onChanged:(v)=>setState(()=>e.value['enabled']=v), title: TextFormField(initialValue:e.value['text'], maxLines:null, onChanged:(v)=>e.value['text']=v))),
    const SizedBox(height: 16), FilledButton.icon(onPressed: ()=>_save(s.data!), icon: const Icon(Icons.save), label: const Text('Save Draft'))
  ])); }); }));
  Widget _dateButton(String label, DateTime value, void Function(DateTime) set) => OutlinedButton.icon(onPressed: () async { final d=await showDatePicker(context:context,initialDate:value,firstDate:DateTime(2000),lastDate:DateTime(2100)); if(d!=null){set(d);setState((){});} }, icon:const Icon(Icons.calendar_month),label:Text('$label: ${DateFormat('dd/MM/yyyy').format(value)}'));
  Future<void> _save(List<TeacherEntity> list) async { if (!key.currentState!.validate()) return; final e=widget.existing??{}; selected ??= list.firstWhere((t)=>t.id==e['teacherId']); final now=Timestamp.now(); final user=sl<AccessControlService>().currentUserEmail ?? 'Unknown user'; final history=List<Map<String,dynamic>>.from((e['auditHistory'] as List? ?? []).map((x)=>Map<String,dynamic>.from(x))); history.add({'action':'Draft saved','at':now,'by':user}); await widget.service.save({'id':e['id']??widget.service.newId(),'letterNumber':e['letterNumber']??widget.service.generateNumber(),'teacherId':selected!.id,'teacherName':selected!.fullName,'employeeId':selected!.employeeId,'fatherName':c['fatherName']!.text.trim(),'cnic':c['cnic']!.text.trim(),'designation':c['designation']!.text.trim(),'branch':c['branch']!.text.trim().isEmpty?'main':c['branch']!.text.trim(),'assignment':c['assignment']!.text.trim(),'monthlySalary':c['monthlySalary']!.text.trim(),'allowancesDeductions':c['allowancesDeductions']!.text.trim(),'workingTimings':c['workingTimings']!.text.trim(),'reportingAuthority':c['reportingAuthority']!.text.trim(),'remarks':c['remarks']!.text.trim(),'employmentType':employment,'issueDate':Timestamp.fromDate(issue),'joiningDate':Timestamp.fromDate(joining),'startDate':Timestamp.fromDate(start),'endDate':Timestamp.fromDate(end),'terms':terms,'witnessesRequired':witnesses,'status':'Draft','version':e['version']??1,'createdAt':e['createdAt']??now,'createdBy':e['createdBy']??user,'updatedAt':now,'updatedBy':user,'auditHistory':history,'unsignedPdfUrl':e['unsignedPdfUrl']??'','signedDocumentUrl':e['signedDocumentUrl']??''}); if(mounted) Navigator.pop(context,true); }
}

class _AppointmentLetterPreview extends StatefulWidget { const _AppointmentLetterPreview({required this.service,required this.letter}); final TeacherAppointmentLetterService service; final Map<String,dynamic> letter; @override State<_AppointmentLetterPreview> createState()=>_AppointmentLetterPreviewState(); }
class _AppointmentLetterPreviewState extends State<_AppointmentLetterPreview> { late Map<String,dynamic> l; late Future<SchoolSettingsEntity> school; @override void initState(){super.initState();l={...widget.letter};school=sl<GetSchoolSettings>()();} @override Widget build(BuildContext context)=>FutureBuilder<SchoolSettingsEntity>(future:school,builder:(_,s){if(!s.hasData)return const Scaffold(body:Center(child:CircularProgressIndicator())); return Scaffold(appBar:AppBar(title:Text(l['letterNumber']),actions:[if(l['status']=='Draft') TextButton.icon(onPressed:()=>_issue(s.data!),icon:const Icon(Icons.send),label:const Text('Issue')),if(l['status']=='Issued') TextButton.icon(onPressed:_uploadSigned,icon:const Icon(Icons.upload_file),label:const Text('Upload Signed')),PopupMenuButton<String>(onSelected:_setStatus,itemBuilder:(_)=>['Rejected','Expired'].map((x)=>PopupMenuItem(value:x,child:Text('Mark $x'))).toList())]),body:PdfPreview(build:(_)=>AppointmentLetterPdfService.build(l,s.data!),canChangePageFormat:false,canChangeOrientation:false,pdfFileName:'${l['letterNumber']}.pdf'));}); Future<void> _issue(SchoolSettingsEntity school) async {final bytes=await AppointmentLetterPdfService.build(l,school);final url=await widget.service.upload(id:l['id'],name:'unsigned_v${l['version']}.pdf',bytes:bytes);final user=sl<AccessControlService>().currentUserEmail ?? 'Unknown user';l={...l,'status':'Issued','unsignedPdfUrl':url,'issuedAt':Timestamp.now(),'approvedBy':user,'auditHistory':[...(l['auditHistory']??[]),{'action':'Letter issued','at':Timestamp.now(),'by':user}]};await widget.service.save(l);if(mounted)setState((){});} Future<void> _uploadSigned() async {final f=await FilePicker.platform.pickFiles(withData:true,type:FileType.custom,allowedExtensions:['pdf','jpg','jpeg','png']);if(f==null)return;final file=f.files.single;final Uint8List? bytes=file.bytes;if(bytes==null)return;final url=await widget.service.upload(id:l['id'],name:'signed_${file.name}',bytes:bytes);final user=sl<AccessControlService>().currentUserEmail ?? 'Unknown user';l={...l,'status':'Signed','signedDocumentUrl':url,'signedAt':Timestamp.now(),'uploadedBy':user,'auditHistory':[...(l['auditHistory']??[]),{'action':'Signed copy uploaded and accepted','at':Timestamp.now(),'by':user}]};await widget.service.save(l);if(mounted)setState((){});} Future<void> _setStatus(String status) async {final user=sl<AccessControlService>().currentUserEmail ?? 'Unknown user';l={...l,'status':status,'auditHistory':[...(l['auditHistory']??[]),{'action':'Marked $status','at':Timestamp.now(),'by':user}]};await widget.service.save(l);if(mounted)setState((){});}}

class _TermsDialog extends StatefulWidget { const _TermsDialog({required this.service,required this.terms});final TeacherAppointmentLetterService service;final List<Map<String,dynamic>> terms;@override State<_TermsDialog> createState()=>_TermsDialogState();}
class _TermsDialogState extends State<_TermsDialog>{@override Widget build(BuildContext context)=>AlertDialog(title:const Text('Appointment Terms Template'),content:SizedBox(width:700,height:500,child:ListView(children:[...widget.terms.asMap().entries.map((e)=>CheckboxListTile(value:e.value['enabled']!=false,onChanged:(v)=>setState(()=>e.value['enabled']=v),title:TextFormField(initialValue:e.value['text'],maxLines:null,onChanged:(v)=>e.value['text']=v))),TextButton.icon(onPressed:()=>setState(()=>widget.terms.add({'enabled':true,'text':'New clause'})),icon:const Icon(Icons.add),label:const Text('Add clause'))])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()async{await widget.service.saveTerms(widget.terms);if(context.mounted)Navigator.pop(context);},child:const Text('Save Template'))]);}
