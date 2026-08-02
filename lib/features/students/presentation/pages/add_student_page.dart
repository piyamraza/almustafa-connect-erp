import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';

import '../bloc/student_bloc.dart';
import '../bloc/student_event.dart';
import '../bloc/student_state.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

class AddStudentPage extends StatefulWidget {
  final StudentEntity? student;

  const AddStudentPage({super.key, this.student});

  bool get isEdit => student != null;

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _studentNameController = TextEditingController();

  final TextEditingController _admissionNoController = TextEditingController();

  final TextEditingController _rollNumberController = TextEditingController();

  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _fatherCnicController = TextEditingController();
  final TextEditingController _fatherPhoneController = TextEditingController();

  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _motherCnicController = TextEditingController();
  final TextEditingController _motherPhoneController = TextEditingController();

  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _guardianCnicController = TextEditingController();

  final TextEditingController _mobileController = TextEditingController();

  final TextEditingController _guardianEmailController =
      TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _medicalAllergiesController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final StudentRepository _repository = sl<StudentRepository>();

  bool _isSaving = false;
  bool _settingSystemAdmissionNumber = false;
  bool _admissionNumberManuallyEdited = false;
  bool _settingSystemRollNumber = false;
  bool _rollNumberManuallyEdited = false;

  Uint8List? _imageBytes;

  String? selectedClass;
  String? selectedSection;
  String? selectedGender;
  String? selectedBloodGroup;

  DateTime? selectedDate;

  List<AcademicClassEntity> _academicClasses = const [];
  List<SectionEntity> _academicSections = const [];

  List<String> get classes {
    final values = _academicClasses
        .where((value) => value.isActive)
        .map((value) => value.name)
        .toList();
    values.sort();
    return values;
  }

  List<String> get sections {
    AcademicClassEntity? academicClass;
    for (final value in _academicClasses) {
      if (value.name == selectedClass) {
        academicClass = value;
        break;
      }
    }
    if (academicClass == null) return const [];
    final values = _academicSections
        .where((value) => value.isActive && value.classId == academicClass!.id)
        .map((value) => value.name)
        .toList();
    values.sort();
    return values;
  }

  final List<String> genders = const ['Male', 'Female'];
  final List<String> bloodGroups = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showManualDatePicker(
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

  void _setSystemRollNumber(String value) {
    _settingSystemRollNumber = true;
    _rollNumberController.text = value;
    _settingSystemRollNumber = false;
  }

  void _setSystemAdmissionNumber(String value) {
    _settingSystemAdmissionNumber = true;
    _admissionNoController.text = value;
    _settingSystemAdmissionNumber = false;
  }

  String _admissionNumberForSequence(int sequence) {
    final year = DateTime.now().year;
    return 'ADM-$year-${sequence.toString().padLeft(4, '0')}';
  }

  Future<void> _loadSystemGeneratedNumbers() async {
    _setSystemAdmissionNumber(_admissionNumberForSequence(1));
    _setSystemRollNumber('1');
    try {
      final students = await _repository.getStudents();
      var highestRollNumber = 0;
      final usedAdmissionNumbers = students
          .map((student) => student.admissionNo.trim().toUpperCase())
          .toSet();
      final admissionPrefix = 'ADM-${DateTime.now().year}-';
      var highestAdmissionSequence = 0;
      for (final student in students) {
        final rollNumber = int.tryParse(student.rollNumber.trim());
        if (rollNumber != null && rollNumber > highestRollNumber) {
          highestRollNumber = rollNumber;
        }
        final admissionNumber = student.admissionNo.trim().toUpperCase();
        if (admissionNumber.startsWith(admissionPrefix)) {
          final sequence = int.tryParse(
            admissionNumber.substring(admissionPrefix.length),
          );
          if (sequence != null && sequence > highestAdmissionSequence) {
            highestAdmissionSequence = sequence;
          }
        }
      }
      var admissionSequence = highestAdmissionSequence + 1;
      while (usedAdmissionNumbers.contains(
        _admissionNumberForSequence(admissionSequence),
      )) {
        admissionSequence++;
      }
      if (!mounted) return;
      if (!_admissionNumberManuallyEdited) {
        _setSystemAdmissionNumber(
          _admissionNumberForSequence(admissionSequence),
        );
      }
      if (!_rollNumberManuallyEdited) {
        _setSystemRollNumber('${highestRollNumber + 1}');
      }
    } catch (_) {
      // Keep the initial generated values when records cannot be loaded.
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
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
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

  Future<bool> _showSaveAnywayDialog(List<String> missingFields) async {
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
                const Text('The following optional fields are empty:'),
                const SizedBox(height: 12),

                ...missingFields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $field'),
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Do you want to save the student anyway?'),
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

  String _selectedClassIdForSave() {
    for (final academicClass in _academicClasses) {
      if (academicClass.id == selectedClass ||
          academicClass.name == selectedClass) {
        return academicClass.name;
      }
    }
    return selectedClass ?? '';
  }

  String _selectedSectionIdForSave() {
    String? selectedClassId;
    for (final academicClass in _academicClasses) {
      if (academicClass.id == selectedClass ||
          academicClass.name == selectedClass) {
        selectedClassId = academicClass.id;
        break;
      }
    }
    for (final section in _academicSections) {
      if ((section.id == selectedSection || section.name == selectedSection) &&
          (selectedClassId == null || section.classId == selectedClassId)) {
        return section.name;
      }
    }
    return selectedSection ?? '';
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final missingFields = _getMissingOptionalFields();

    if (missingFields.isNotEmpty) {
      final shouldContinue = await _showSaveAnywayDialog(missingFields);

      if (!shouldContinue) {
        return;
      }

      if (!mounted) return;
    }

    setState(() {
      _isSaving = true;
    });

    final studentId = widget.isEdit
        ? widget.student!.id
        : _repository.generateStudentId();
    final fullName = _studentNameController.text.trim();

    final nameParts = fullName.split(' ');

    final firstName = nameParts.isNotEmpty ? nameParts.first : '';

    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final admissionNo = _admissionNoController.text.trim().isEmpty
        ? 'ADM-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch}'
        : _admissionNoController.text.trim();
    String imageUrl = '';

    if (_imageBytes != null) {
      imageUrl = await _repository.uploadStudentPhoto(studentId, _imageBytes!);
    }
    if (!mounted) return;
    final student = StudentEntity(
      id: studentId,
      admissionNo: admissionNo,
      rollNumber: _rollNumberController.text.trim(),
      firstName: firstName,
      lastName: lastName,
      gender: selectedGender!,
      dateOfBirth: selectedDate ?? DateTime.now(),
      classId: _selectedClassIdForSave(),
      sectionId: _selectedSectionIdForSave(),
      fatherName: _fatherNameController.text.trim(),
      fatherCnic: _fatherCnicController.text.trim(),
      fatherPhone: _fatherPhoneController.text.trim(),
      motherName: _motherNameController.text.trim(),
      motherCnic: _motherCnicController.text.trim(),
      motherPhone: _motherPhoneController.text.trim(),
      guardianName: _guardianNameController.text.trim(),
      guardianCnic: _guardianCnicController.text.trim(),
      guardianPhone: _mobileController.text.trim(),
      guardianEmail: _guardianEmailController.text.trim(),
      bloodGroup: selectedBloodGroup ?? '',
      medicalAllergies: _medicalAllergiesController.text.trim(),
      address: _addressController.text.trim(),
      profileImageUrl: imageUrl,
      isActive: widget.isEdit ? widget.student!.isActive : true,
      createdAt: widget.isEdit ? widget.student!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _isSaving = true;
    if (widget.isEdit) {
      context.read<StudentBloc>().add(UpdateStudentEvent(student));
    } else {
      context.read<StudentBloc>().add(AddStudentEvent(student));
    }
  }

  @override
  void initState() {
    super.initState();

    _loadAcademicStructure();

    if (!widget.isEdit) {
      _admissionNoController.addListener(() {
        if (!_settingSystemAdmissionNumber) {
          _admissionNumberManuallyEdited = true;
        }
      });
      _rollNumberController.addListener(() {
        if (!_settingSystemRollNumber) {
          _rollNumberManuallyEdited = true;
        }
      });
      _loadSystemGeneratedNumbers();
      return;
    }

    final student = widget.student!;

    _studentNameController.text = student.fullName;
    _admissionNoController.text = student.admissionNo;
    _rollNumberController.text = student.rollNumber;
    _fatherNameController.text = student.fatherName;
    _fatherCnicController.text = student.fatherCnic;
    _fatherPhoneController.text = student.fatherPhone;
    _motherNameController.text = student.motherName;
    _motherCnicController.text = student.motherCnic;
    _motherPhoneController.text = student.motherPhone;
    _guardianNameController.text = student.guardianName;
    _guardianCnicController.text = student.guardianCnic;
    _mobileController.text = student.guardianPhone;
    _guardianEmailController.text = student.guardianEmail;
    _addressController.text = student.address;

    selectedClass = student.classId;
    selectedSection = student.sectionId;
    selectedGender = student.gender;
    selectedBloodGroup = student.bloodGroup.isEmpty ? null : student.bloodGroup;
    selectedDate = student.dateOfBirth;
    _medicalAllergiesController.text = student.medicalAllergies;

    _dobController.text =
        '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';
  }

  Future<void> _loadAcademicStructure() async {
    try {
      final repository = sl<AcademicStructureRepository>();
      final data = await Future.wait<Object>([
        repository.getClasses(),
        repository.getSections(),
      ]);
      if (!mounted) return;
      final storedClass = selectedClass;
      final storedSection = selectedSection;
      setState(() {
        _academicClasses = data[0] as List<AcademicClassEntity>;
        _academicSections = data[1] as List<SectionEntity>;
        AcademicClassEntity? matchingClass;
        for (final academicClass in _academicClasses) {
          if (academicClass.id == storedClass ||
              academicClass.name == storedClass) {
            matchingClass = academicClass;
            break;
          }
        }
        selectedClass = matchingClass?.name;

        SectionEntity? matchingSection;
        for (final section in _academicSections) {
          if ((section.id == storedSection || section.name == storedSection) &&
              (matchingClass == null || section.classId == matchingClass.id)) {
            matchingSection = section;
            break;
          }
        }
        // Recover records created before section selection was scoped by class:
        // use the old section's name, then resolve that name inside this class.
        if (matchingSection == null && matchingClass != null) {
          String? legacySectionName;
          for (final section in _academicSections) {
            if (section.id == storedSection) {
              legacySectionName = section.name;
              break;
            }
          }
          if (legacySectionName != null) {
            for (final section in _academicSections) {
              if (section.classId == matchingClass.id &&
                  section.name == legacySectionName) {
                matchingSection = section;
                break;
              }
            }
          }
        }
        selectedSection = matchingSection?.name;
      });
    } catch (_) {
      // The existing form remains usable while the master data is unavailable.
    }
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _admissionNoController.dispose();
    _rollNumberController.dispose();
    _fatherNameController.dispose();
    _fatherCnicController.dispose();
    _fatherPhoneController.dispose();
    _motherNameController.dispose();
    _motherCnicController.dispose();
    _motherPhoneController.dispose();
    _guardianNameController.dispose();
    _guardianCnicController.dispose();
    _mobileController.dispose();
    _guardianEmailController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _medicalAllergiesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocListener<StudentBloc, StudentState>(
      listener: (context, state) {
        if (state is StudentLoading && !_isSaving) {
          return;
        }

        if (state is StudentLoading) {
          _showLoadingDialog();
        } else if (state is StudentLoaded && _isSaving) {
          _hideLoadingDialog();

          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student added successfully')),
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

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          actions: const [DashboardNavigationButton()],
          title: Text(widget.isEdit ? 'Edit Student' : 'Add Student'),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
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
                                ? const Icon(Icons.person, size: 55)
                                : null,
                          ),

                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                color: Colors.white,
                                onPressed: _showImagePicker,
                                icon: const Icon(Icons.camera_alt),
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
                              controller: _studentNameController,
                              label: 'Student Name',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Student Name is required';
                                }

                                return null;
                              },
                            ),
                          ),

                          const SizedBox(width: 20),

                          Expanded(
                            child: _textField(
                              controller: _admissionNoController,
                              label: 'Admission No.',
                              icon: Icons.badge,
                              helperText:
                                  'System generated; manual entry allowed',
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
                              helperText:
                                  'Next number suggested; manual entry allowed',
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
                        controller: _studentNameController,
                        label: 'Student Name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Student Name is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _textField(
                        controller: _admissionNoController,
                        label: 'Admission No.',
                        icon: Icons.badge,
                        helperText: 'System generated; manual entry allowed',
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
                        helperText:
                            'Next number suggested; manual entry allowed',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Roll Number is required';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 16),

                    _sectionTitle('Parent & Guardian Information'),

                    const SizedBox(height: 20),

                    _familyInformationRow(
                      isDesktop: isDesktop,
                      relation: 'Father',
                      nameController: _fatherNameController,
                      cnicController: _fatherCnicController,
                      phoneController: _fatherPhoneController,
                      nameRequired: true,
                    ),

                    const SizedBox(height: 16),

                    _familyInformationRow(
                      isDesktop: isDesktop,
                      relation: 'Mother',
                      nameController: _motherNameController,
                      cnicController: _motherCnicController,
                      phoneController: _motherPhoneController,
                    ),

                    const SizedBox(height: 16),

                    _familyInformationRow(
                      isDesktop: isDesktop,
                      relation: 'Guardian',
                      nameController: _guardianNameController,
                      cnicController: _guardianCnicController,
                      phoneController: _mobileController,
                    ),

                    const SizedBox(height: 35),

                    _sectionTitle('Academic Information'),

                    const SizedBox(height: 20),
                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedClass,
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
                                  selectedSection = null;
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 20),

                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedSection,
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
                        initialValue: selectedClass,
                        decoration: _inputDecoration('Class', Icons.school),
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
                            selectedSection = null;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedSection,
                        decoration: _inputDecoration('Section', Icons.groups),
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

                    _sectionTitle('Personal Information'),

                    const SizedBox(height: 20),

                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedGender,
                              decoration: _inputDecoration('Gender', Icons.wc),
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
                        initialValue: selectedGender,
                        decoration: _inputDecoration('Gender', Icons.wc),
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
                        validator: (value) {
                          return null;
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
                      controller: _guardianEmailController,
                      label: 'Guardian Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }

                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 35),

                    _sectionTitle('Medical Information'),

                    const SizedBox(height: 20),

                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedBloodGroup,
                              decoration: _inputDecoration(
                                'Blood Group',
                                Icons.bloodtype_outlined,
                              ),
                              items: bloodGroups
                                  .map(
                                    (group) => DropdownMenuItem(
                                      value: group,
                                      child: Text(group),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => selectedBloodGroup = value),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: _textField(
                              controller: _medicalAllergiesController,
                              label: 'Medical Allergies (if any)',
                              icon: Icons.medical_information_outlined,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedBloodGroup,
                        decoration: _inputDecoration(
                          'Blood Group',
                          Icons.bloodtype_outlined,
                        ),
                        items: bloodGroups
                            .map(
                              (group) => DropdownMenuItem(
                                value: group,
                                child: Text(group),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedBloodGroup = value),
                      ),
                      const SizedBox(height: 16),
                      _textField(
                        controller: _medicalAllergiesController,
                        label: 'Medical Allergies (if any)',
                        icon: Icons.medical_information_outlined,
                        maxLines: 3,
                      ),
                    ],

                    const SizedBox(height: 35),

                    _sectionTitle('Contact Information'),

                    const SizedBox(height: 20),

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
                          widget.isEdit ? 'Update Student' : 'Save Student',
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

  Widget _familyInformationRow({
    required bool isDesktop,
    required String relation,
    required TextEditingController nameController,
    required TextEditingController cnicController,
    required TextEditingController phoneController,
    bool nameRequired = false,
  }) {
    final fields = <Widget>[
      _textField(
        controller: nameController,
        label: '$relation Name',
        icon: Icons.family_restroom,
        validator: nameRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$relation Name is required';
                }
                return null;
              }
            : null,
      ),
      _textField(
        controller: cnicController,
        label: '$relation CNIC #',
        icon: Icons.credit_card_outlined,
        keyboardType: TextInputType.number,
        validator: _validateCnic,
      ),
      _textField(
        controller: phoneController,
        label: '$relation Mobile Number',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        validator: _validateMobile,
      ),
    ];
    if (!isDesktop) {
      return Column(
        children: [
          fields[0],
          const SizedBox(height: 16),
          fields[1],
          const SizedBox(height: 16),
          fields[2],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: fields[0]),
        const SizedBox(width: 20),
        Expanded(child: fields[1]),
        const SizedBox(width: 20),
        Expanded(child: fields[2]),
      ],
    );
  }

  String? _validateCnic(String? value) {
    final cnic = value?.trim() ?? '';
    if (cnic.isEmpty) return null;
    if (!RegExp(r'^\d{13}$').hasMatch(cnic)) {
      return 'CNIC must contain exactly 13 digits';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    final mobile = value?.trim() ?? '';
    if (mobile.isEmpty) return null;
    if (!RegExp(r'^\d{11}$').hasMatch(mobile)) {
      return 'Mobile number must contain exactly 11 digits';
    }
    return null;
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
    String? helperText,
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
      ).copyWith(hintText: hintText, helperText: helperText),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
