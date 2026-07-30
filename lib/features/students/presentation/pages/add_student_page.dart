import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';

import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';

import '../bloc/student_bloc.dart';
import '../bloc/student_event.dart';
import '../bloc/student_state.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';


class AddStudentPage extends StatefulWidget {
  final StudentEntity? student;

  const AddStudentPage({
    super.key,
    this.student,
  });

  bool get isEdit => student != null;

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}
class _AddStudentPageState extends State<AddStudentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  final TextEditingController _studentNameController =
      TextEditingController();

  final TextEditingController _admissionNoController =
      TextEditingController();

  final TextEditingController _rollNumberController =
      TextEditingController();

final TextEditingController _fatherNameController =
    TextEditingController();

final TextEditingController _motherNameController =
    TextEditingController();

final TextEditingController _mobileController =
    TextEditingController();

final TextEditingController _guardianEmailController =
    TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _dobController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();
final StudentRepository _repository =
    sl<StudentRepository>();

bool _isSaving = false;

Uint8List? _imageBytes;

  String? selectedClass;
  String? selectedSection;
  String? selectedGender;

  DateTime? selectedDate;

  final List<String> classes = const [
    'Nursery',
    'KG',
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

  final List<String> sections = const [
    'A',
    'B',
    'C',
    'D',
  ];

  final List<String> genders = const [
    'Male',
    'Female',
  ];


  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2015),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;

        _dobController.text =
            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
      });
    }
  }

Future<void> _pickImage(ImageSource source) async {
  final XFile? image = await _picker.pickImage(
    source: source,
    imageQuality: 80,
  );

  if (image == null) return;

  final bytes = await image.readAsBytes();

setState(() {
  _imageBytes = bytes;
});
}

Future<void> _showImagePicker() async {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showLoadingDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );
}

void _hideLoadingDialog() {
  Navigator.of(
    context,
    rootNavigator: true,
  ).pop();
}
List<String> _getMissingOptionalFields() {
  final missing = <String>[];


  if (_motherNameController.text.trim().isEmpty) {
    missing.add('Mother Name');
  }

  if (_mobileController.text.trim().isEmpty) {
    missing.add('Guardian Mobile');
  }

  if (_guardianEmailController.text.trim().isEmpty) {
    missing.add('Guardian Email');
  }

  if (selectedSection == null) {
    missing.add('Section');
  }

  if (selectedDate == null) {
    missing.add('Date of Birth');
  }

  if (_addressController.text.trim().isEmpty) {
    missing.add('Address');
  }

  return missing;
}
Future<bool> _showSaveAnywayDialog(
  List<String> missingFields,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Optional Information Missing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following optional fields are empty:',
              ),
              const SizedBox(height: 12),

              ...missingFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $field'),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Do you want to save the student anyway?',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Save Anyway'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
Future<void> _saveStudent() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }
final missingFields = _getMissingOptionalFields();

if (missingFields.isNotEmpty) {
  final shouldContinue =
      await _showSaveAnywayDialog(missingFields);

  if (!shouldContinue) {
    return;
  }
}

  setState(() {
    _isSaving = true;
  });

 
   final studentId = widget.isEdit
    ? widget.student!.id
    : _repository.generateStudentId();
final fullName = _studentNameController.text.trim();

final nameParts = fullName.split(' ');

final firstName =
    nameParts.isNotEmpty ? nameParts.first : '';

final lastName =
    nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';
final admissionNo =
    _admissionNoController.text.trim().isEmpty
        ? 'ADM${DateTime.now().millisecondsSinceEpoch}'
        : _admissionNoController.text.trim();
    String imageUrl = '';

    if (_imageBytes != null) {
  imageUrl = await _repository.uploadStudentPhoto(
    studentId,
    _imageBytes!,
  );
}
    final student = StudentEntity(
      id: studentId,
      admissionNo: admissionNo,
      rollNumber: _rollNumberController.text.trim(),
      firstName: firstName,
      lastName: lastName,
      gender: selectedGender!,
      dateOfBirth: selectedDate ?? DateTime.now(),
      classId: selectedClass!,
      sectionId: selectedSection ?? '',
      fatherName: _fatherNameController.text.trim(),
      motherName: _motherNameController.text.trim(),
      guardianPhone: _mobileController.text.trim(),
      guardianEmail: _guardianEmailController.text.trim(),
      address: _addressController.text.trim(),
      profileImageUrl: imageUrl,
      isActive: true,
      createdAt: widget.isEdit
    ? widget.student!.createdAt
    : DateTime.now(),
      updatedAt: DateTime.now(),
    );
_isSaving = true;
    if (widget.isEdit) {
  context.read<StudentBloc>().add(
    UpdateStudentEvent(student),
  );
} else {
  context.read<StudentBloc>().add(
    AddStudentEvent(student),
  );
}

   }
@override
void initState() {
  super.initState();

  if (!widget.isEdit) return;

  final student = widget.student!;

  _studentNameController.text = student.fullName;
  _admissionNoController.text = student.admissionNo;
  _rollNumberController.text = student.rollNumber;
  _fatherNameController.text = student.fatherName;
  _motherNameController.text = student.motherName;
  _mobileController.text = student.guardianPhone;
  _guardianEmailController.text = student.guardianEmail;
  _addressController.text = student.address;

  selectedClass = student.classId;
  selectedSection = student.sectionId;
  selectedGender = student.gender;
  selectedDate = student.dateOfBirth;

  _dobController.text =
      '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';
}
  @override
  void dispose() {
_studentNameController.dispose();
_admissionNoController.dispose();
_rollNumberController.dispose();
_fatherNameController.dispose();
_motherNameController.dispose();
_mobileController.dispose();
_guardianEmailController.dispose();
_addressController.dispose();
_dobController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.of(context).size.width > 900;

    return BlocListener<StudentBloc, StudentState>(
  listener: (context, state) {
  if (state is StudentLoading && !_isSaving) {
  return;
}

if (state is StudentLoading) {
  _showLoadingDialog();
}
else if (
    state is StudentLoaded &&
    _isSaving
) {
    _hideLoadingDialog();

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student added successfully'),
      ),
    );

    if (Navigator.canPop(context)) {
  Navigator.of(context).pop(true);
}
  } else if (state is StudentError) {
    _hideLoadingDialog();

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.message),
      ),
    );
  }
},
  child: Scaffold(
      appBar: AppBar(
        title: Text(
  widget.isEdit ? 'Edit Student' : 'Add Student',
),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
  radius: 55,
  backgroundImage: _imageBytes != null
      ? MemoryImage(_imageBytes!)
      : null,
  child: _imageBytes == null
      ? const Icon(
          Icons.person,
          size: 55,
        )
      : null,
),

                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                Theme.of(context)
                                    .colorScheme
                                    .primary,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              color: Colors.white,
                              onPressed: _showImagePicker,
                              icon: const Icon(
                                Icons.camera_alt,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  _sectionTitle('Basic Information'),

                  const SizedBox(height: 20),

                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller:
                                _studentNameController,
                            label: 'Student Name',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Student Name is required';
                              }

                              return null;
                            },
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: _textField(
                            controller:
                                _admissionNoController,
                            label: 'Admission No.',
                            icon: Icons.badge,
                            validator: (value) {

                              return null;
                            },
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: _textField(
                            controller: _rollNumberController,
                            label: 'Roll Number',
                            icon: Icons.format_list_numbered,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Roll Number is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _textField(
                      controller:
                          _studentNameController,
                      label: 'Student Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Student Name is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _textField(
                      controller:
                          _admissionNoController,
                      label: 'Admission No.',
                      icon: Icons.badge,
                      validator: (value) {
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _textField(
                      controller: _rollNumberController,
                      label: 'Roll Number',
                      icon: Icons.format_list_numbered,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Roll Number is required';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  _textField(
                    controller: _fatherNameController,
                    label: 'Father Name',
                    icon: Icons.family_restroom,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Father Name is required';
                      }

                      return null;
                    },
                  ),
const SizedBox(height: 16),

_textField(
  controller: _motherNameController,
  label: 'Mother Name',
  icon: Icons.family_restroom,
),

                  const SizedBox(height: 35),

                  _sectionTitle(
                    'Academic Information',
                  ),

                  const SizedBox(height: 20),
                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedClass,
                            decoration: _inputDecoration(
                              'Class',
                              Icons.school,
                            ),
                            items: classes
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select Class';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                selectedClass = value;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedSection,
                            decoration: _inputDecoration(
                              'Section',
                              Icons.groups,
                            ),
                            items: sections
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            validator: (value) {
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                selectedSection = value;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      value: selectedClass,
                      decoration: _inputDecoration(
                        'Class',
                        Icons.school,
                      ),
                      items: classes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select Class';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          selectedClass = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedSection,
                      decoration: _inputDecoration(
                        'Section',
                        Icons.groups,
                      ),
                      items: sections
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
 validator: (value) {
    return null;
  },
                      onChanged: (value) {
                        setState(() {
                          selectedSection = value;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 35),

                  _sectionTitle(
                    'Personal Information',
                  ),

                  const SizedBox(height: 20),

                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedGender,
                            decoration: _inputDecoration(
                              'Gender',
                              Icons.wc,
                            ),
                            items: genders
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select Gender';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                selectedGender = value;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            validator: (value) {
                              return null;
                            },
                            onTap: _pickDate,
                            decoration: _inputDecoration(
                              'Date of Birth',
                              Icons.calendar_today,
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: _inputDecoration(
                        'Gender',
                        Icons.wc,
                      ),
                      items: genders
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select Gender';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      validator: (value) {                        return null;
                      },
                      onTap: _pickDate,
                      decoration: _inputDecoration(
                        'Date of Birth',
                        Icons.calendar_today,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                 _textField(
  controller: _mobileController,
  label: 'Guardian Mobile',
  icon: Icons.phone,
  keyboardType: TextInputType.phone,
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (!RegExp(r'^\d{11}$').hasMatch(value.trim())) {
      return 'Mobile Number must be exactly 11 digits';
    }

    return null;
  },
),

const SizedBox(height: 16),

_textField(
  controller: _guardianEmailController,
  label: 'Guardian Email',
  icon: Icons.email,
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final emailRegex =
        RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  },
),

                  const SizedBox(height: 16),

                  _textField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.home,
                    maxLines: 3,
                    validator: (value) {
  return null;
},
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveStudent,
                      icon: const Icon(Icons.save),
                      label: Text(
  widget.isEdit
      ? 'Update Student'
      : 'Save Student',
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
           ),
    ),
  );
}

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(
        label,
        icon,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
    );
  }
}
