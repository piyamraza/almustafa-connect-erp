[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\student_whatsapp_$stamp"

function Full([string]$Path) { Join-Path $root $Path }
function ReadText([string]$Path) { [IO.File]::ReadAllText((Full $Path)) }
function WriteText([string]$Path,[string]$Text) {
  $full = Full $Path
  [IO.File]::WriteAllText($full,$Text.Replace("`r`n","`n"),$utf8)
}
function BackupFile([string]$Path) {
  $source = Full $Path
  $target = Join-Path $backup $Path
  $dir = Split-Path $target -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  Copy-Item $source $target -Force
}
function ReplaceOnce([string]$Text,[string]$Old,[string]$New,[string]$Label) {
  if ($Text.Contains($New.Trim())) { return $Text }
  if (-not $Text.Contains($Old)) { throw "ANCHOR ERROR: $Label" }
  return $Text.Replace($Old,$New)
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run this script from the Flutter project root.'
}

$entityFile = 'lib/features/students/domain/entities/student_entity.dart'
$modelFile = 'lib/features/students/data/models/student_model.dart'
$pageFile = 'lib/features/students/presentation/pages/add_student_page.dart'

foreach ($file in @($entityFile,$modelFile,$pageFile)) {
  if (-not (Test-Path (Full $file))) { throw "REQUIRED FILE ERROR: $file" }
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($file in @($entityFile,$modelFile,$pageFile)) { BackupFile $file }

$entity = ReadText $entityFile

$entity = ReplaceOnce $entity @'
  final String fatherPhone;
  final String motherName;
'@ @'
  final String fatherPhone;
  final String fatherWhatsapp;
  final String motherName;
'@ 'entity father field'

$entity = ReplaceOnce $entity @'
  final String motherPhone;
  final String guardianName;
'@ @'
  final String motherPhone;
  final String motherWhatsapp;
  final String guardianName;
'@ 'entity mother field'

$entity = ReplaceOnce $entity @'
  final String guardianPhone;
  final String guardianEmail;
'@ @'
  final String guardianPhone;
  final String guardianWhatsapp;
  final String guardianEmail;
'@ 'entity guardian field'

$entity = ReplaceOnce $entity @'
    this.fatherPhone = '',
    required this.motherName,
'@ @'
    this.fatherPhone = '',
    this.fatherWhatsapp = '',
    required this.motherName,
'@ 'entity father constructor'

$entity = ReplaceOnce $entity @'
    this.motherPhone = '',
    this.guardianName = '',
'@ @'
    this.motherPhone = '',
    this.motherWhatsapp = '',
    this.guardianName = '',
'@ 'entity mother constructor'

$entity = ReplaceOnce $entity @'
    required this.guardianPhone,
    required this.guardianEmail,
'@ @'
    required this.guardianPhone,
    this.guardianWhatsapp = '',
    required this.guardianEmail,
'@ 'entity guardian constructor'

$entity = ReplaceOnce $entity @'
    String? fatherPhone,
    String? motherName,
'@ @'
    String? fatherPhone,
    String? fatherWhatsapp,
    String? motherName,
'@ 'entity copy father args'

$entity = ReplaceOnce $entity @'
    String? motherPhone,
    String? guardianName,
'@ @'
    String? motherPhone,
    String? motherWhatsapp,
    String? guardianName,
'@ 'entity copy mother args'

$entity = ReplaceOnce $entity @'
    String? guardianPhone,
    String? guardianEmail,
'@ @'
    String? guardianPhone,
    String? guardianWhatsapp,
    String? guardianEmail,
'@ 'entity copy guardian args'

$entity = ReplaceOnce $entity @'
      fatherPhone: fatherPhone ?? this.fatherPhone,
      motherName: motherName ?? this.motherName,
'@ @'
      fatherPhone: fatherPhone ?? this.fatherPhone,
      fatherWhatsapp: fatherWhatsapp ?? this.fatherWhatsapp,
      motherName: motherName ?? this.motherName,
'@ 'entity copy father values'

$entity = ReplaceOnce $entity @'
      motherPhone: motherPhone ?? this.motherPhone,
      guardianName: guardianName ?? this.guardianName,
'@ @'
      motherPhone: motherPhone ?? this.motherPhone,
      motherWhatsapp: motherWhatsapp ?? this.motherWhatsapp,
      guardianName: guardianName ?? this.guardianName,
'@ 'entity copy mother values'

$entity = ReplaceOnce $entity @'
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
'@ @'
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianWhatsapp: guardianWhatsapp ?? this.guardianWhatsapp,
      guardianEmail: guardianEmail ?? this.guardianEmail,
'@ 'entity copy guardian values'

WriteText $entityFile $entity

$model = ReadText $modelFile

$model = ReplaceOnce $model @'
    super.fatherPhone,
    required super.motherName,
'@ @'
    super.fatherPhone,
    super.fatherWhatsapp,
    required super.motherName,
'@ 'model father constructor'

$model = ReplaceOnce $model @'
    super.motherPhone,
    super.guardianName,
'@ @'
    super.motherPhone,
    super.motherWhatsapp,
    super.guardianName,
'@ 'model mother constructor'

$model = ReplaceOnce $model @'
    required super.guardianPhone,
    required super.guardianEmail,
'@ @'
    required super.guardianPhone,
    super.guardianWhatsapp,
    required super.guardianEmail,
'@ 'model guardian constructor'

$model = ReplaceOnce $model @'
      fatherPhone: map['fatherPhone'] ?? '',
      motherName: map['motherName'] ?? '',
'@ @'
      fatherPhone: map['fatherPhone'] ?? '',
      fatherWhatsapp: map['fatherWhatsapp'] ?? map['fatherPhone'] ?? '',
      motherName: map['motherName'] ?? '',
'@ 'model fromMap father'

$model = ReplaceOnce $model @'
      motherPhone: map['motherPhone'] ?? '',
      guardianName: map['guardianName'] ?? '',
'@ @'
      motherPhone: map['motherPhone'] ?? '',
      motherWhatsapp: map['motherWhatsapp'] ?? map['motherPhone'] ?? '',
      guardianName: map['guardianName'] ?? '',
'@ 'model fromMap mother'

$model = ReplaceOnce $model @'
      guardianPhone: map['guardianPhone'] ?? '',
      guardianEmail: map['guardianEmail'] ?? '',
'@ @'
      guardianPhone: map['guardianPhone'] ?? '',
      guardianWhatsapp: map['guardianWhatsapp'] ?? map['guardianPhone'] ?? '',
      guardianEmail: map['guardianEmail'] ?? '',
'@ 'model fromMap guardian'

$model = ReplaceOnce $model @'
      'fatherPhone': fatherPhone,
      'motherName': motherName,
'@ @'
      'fatherPhone': fatherPhone,
      'fatherWhatsapp': fatherWhatsapp,
      'motherName': motherName,
'@ 'model toMap father'

$model = ReplaceOnce $model @'
      'motherPhone': motherPhone,
      'guardianName': guardianName,
'@ @'
      'motherPhone': motherPhone,
      'motherWhatsapp': motherWhatsapp,
      'guardianName': guardianName,
'@ 'model toMap mother'

$model = ReplaceOnce $model @'
      'guardianPhone': guardianPhone,
      'guardianEmail': guardianEmail,
'@ @'
      'guardianPhone': guardianPhone,
      'guardianWhatsapp': guardianWhatsapp,
      'guardianEmail': guardianEmail,
'@ 'model toMap guardian'

$model = ReplaceOnce $model @'
      fatherPhone: entity.fatherPhone,
      motherName: entity.motherName,
'@ @'
      fatherPhone: entity.fatherPhone,
      fatherWhatsapp: entity.fatherWhatsapp,
      motherName: entity.motherName,
'@ 'model fromEntity father'

$model = ReplaceOnce $model @'
      motherPhone: entity.motherPhone,
      guardianName: entity.guardianName,
'@ @'
      motherPhone: entity.motherPhone,
      motherWhatsapp: entity.motherWhatsapp,
      guardianName: entity.guardianName,
'@ 'model fromEntity mother'

$model = ReplaceOnce $model @'
      guardianPhone: entity.guardianPhone,
      guardianEmail: entity.guardianEmail,
'@ @'
      guardianPhone: entity.guardianPhone,
      guardianWhatsapp: entity.guardianWhatsapp,
      guardianEmail: entity.guardianEmail,
'@ 'model fromEntity guardian'

WriteText $modelFile $model

$page = ReadText $pageFile

$page = ReplaceOnce $page @'
  final TextEditingController _fatherPhoneController = TextEditingController();

  final TextEditingController _motherNameController = TextEditingController();
'@ @'
  final TextEditingController _fatherPhoneController = TextEditingController();
  final TextEditingController _fatherWhatsappController =
      TextEditingController();

  final TextEditingController _motherNameController = TextEditingController();
'@ 'page father controller'

$page = ReplaceOnce $page @'
  final TextEditingController _motherPhoneController = TextEditingController();

  final TextEditingController _guardianNameController = TextEditingController();
'@ @'
  final TextEditingController _motherPhoneController = TextEditingController();
  final TextEditingController _motherWhatsappController =
      TextEditingController();

  final TextEditingController _guardianNameController = TextEditingController();
'@ 'page mother controller'

$page = ReplaceOnce $page @'
  final TextEditingController _mobileController = TextEditingController();

  final TextEditingController _guardianEmailController =
'@ @'
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _guardianWhatsappController =
      TextEditingController();

  final TextEditingController _guardianEmailController =
'@ 'page guardian controller'

$page = ReplaceOnce $page @'
  bool _admissionNumberManuallyEdited = false;

  Uint8List? _imageBytes;
'@ @'
  bool _admissionNumberManuallyEdited = false;
  bool _fatherWhatsappSame = true;
  bool _motherWhatsappSame = true;
  bool _guardianWhatsappSame = true;

  Uint8List? _imageBytes;
'@ 'page booleans'

$page = ReplaceOnce $page @'
  Future<void> _pickDate() async {
'@ @'
  void _syncFatherWhatsapp() {
    if (_fatherWhatsappSame) {
      _fatherWhatsappController.text = _fatherPhoneController.text;
    }
  }

  void _syncMotherWhatsapp() {
    if (_motherWhatsappSame) {
      _motherWhatsappController.text = _motherPhoneController.text;
    }
  }

  void _syncGuardianWhatsapp() {
    if (_guardianWhatsappSame) {
      _guardianWhatsappController.text = _mobileController.text;
    }
  }

  Future<void> _pickDate() async {
'@ 'page sync methods'

$page = ReplaceOnce $page @'
      fatherPhone: _fatherPhoneController.text.trim(),
      motherName: _motherNameController.text.trim(),
'@ @'
      fatherPhone: _fatherPhoneController.text.trim(),
      fatherWhatsapp: _fatherWhatsappController.text.trim(),
      motherName: _motherNameController.text.trim(),
'@ 'page save father'

$page = ReplaceOnce $page @'
      motherPhone: _motherPhoneController.text.trim(),
      guardianName: _guardianNameController.text.trim(),
'@ @'
      motherPhone: _motherPhoneController.text.trim(),
      motherWhatsapp: _motherWhatsappController.text.trim(),
      guardianName: _guardianNameController.text.trim(),
'@ 'page save mother'

$page = ReplaceOnce $page @'
      guardianPhone: _mobileController.text.trim(),
      guardianEmail: _guardianEmailController.text.trim(),
'@ @'
      guardianPhone: _mobileController.text.trim(),
      guardianWhatsapp: _guardianWhatsappController.text.trim(),
      guardianEmail: _guardianEmailController.text.trim(),
'@ 'page save guardian'

$page = ReplaceOnce $page @'
    _loadAcademicStructure();

    if (!widget.isEdit) {
'@ @'
    _fatherPhoneController.addListener(_syncFatherWhatsapp);
    _motherPhoneController.addListener(_syncMotherWhatsapp);
    _mobileController.addListener(_syncGuardianWhatsapp);

    _loadAcademicStructure();

    if (!widget.isEdit) {
'@ 'page init listeners'

$page = ReplaceOnce $page @'
    _fatherPhoneController.text = student.fatherPhone;
    _motherNameController.text = student.motherName;
'@ @'
    _fatherPhoneController.text = student.fatherPhone;
    _fatherWhatsappController.text = student.fatherWhatsapp.isEmpty
        ? student.fatherPhone
        : student.fatherWhatsapp;
    _fatherWhatsappSame =
        _fatherWhatsappController.text == _fatherPhoneController.text;
    _motherNameController.text = student.motherName;
'@ 'page edit father'

$page = ReplaceOnce $page @'
    _motherPhoneController.text = student.motherPhone;
    _guardianNameController.text = student.guardianName;
'@ @'
    _motherPhoneController.text = student.motherPhone;
    _motherWhatsappController.text = student.motherWhatsapp.isEmpty
        ? student.motherPhone
        : student.motherWhatsapp;
    _motherWhatsappSame =
        _motherWhatsappController.text == _motherPhoneController.text;
    _guardianNameController.text = student.guardianName;
'@ 'page edit mother'

$page = ReplaceOnce $page @'
    _mobileController.text = student.guardianPhone;
    _guardianEmailController.text = student.guardianEmail;
'@ @'
    _mobileController.text = student.guardianPhone;
    _guardianWhatsappController.text = student.guardianWhatsapp.isEmpty
        ? student.guardianPhone
        : student.guardianWhatsapp;
    _guardianWhatsappSame =
        _guardianWhatsappController.text == _mobileController.text;
    _guardianEmailController.text = student.guardianEmail;
'@ 'page edit guardian'

$page = ReplaceOnce $page @'
    _fatherPhoneController.dispose();
    _motherNameController.dispose();
'@ @'
    _fatherPhoneController.removeListener(_syncFatherWhatsapp);
    _fatherPhoneController.dispose();
    _fatherWhatsappController.dispose();
    _motherNameController.dispose();
'@ 'page dispose father'

$page = ReplaceOnce $page @'
    _motherPhoneController.dispose();
    _guardianNameController.dispose();
'@ @'
    _motherPhoneController.removeListener(_syncMotherWhatsapp);
    _motherPhoneController.dispose();
    _motherWhatsappController.dispose();
    _guardianNameController.dispose();
'@ 'page dispose mother'

$page = ReplaceOnce $page @'
    _mobileController.dispose();
    _guardianEmailController.dispose();
'@ @'
    _mobileController.removeListener(_syncGuardianWhatsapp);
    _mobileController.dispose();
    _guardianWhatsappController.dispose();
    _guardianEmailController.dispose();
'@ 'page dispose guardian'

$page = ReplaceOnce $page @'
                      phoneController: _fatherPhoneController,
                      nameRequired: true,
'@ @'
                      phoneController: _fatherPhoneController,
                      whatsappController: _fatherWhatsappController,
                      sameWhatsapp: _fatherWhatsappSame,
                      onSameWhatsappChanged: (value) {
                        setState(() {
                          _fatherWhatsappSame = value;
                          if (value) _syncFatherWhatsapp();
                        });
                      },
                      nameRequired: true,
'@ 'page father call'

$page = ReplaceOnce $page @'
                      phoneController: _motherPhoneController,
                    ),
'@ @'
                      phoneController: _motherPhoneController,
                      whatsappController: _motherWhatsappController,
                      sameWhatsapp: _motherWhatsappSame,
                      onSameWhatsappChanged: (value) {
                        setState(() {
                          _motherWhatsappSame = value;
                          if (value) _syncMotherWhatsapp();
                        });
                      },
                    ),
'@ 'page mother call'

$page = ReplaceOnce $page @'
                      phoneController: _mobileController,
                    ),
'@ @'
                      phoneController: _mobileController,
                      whatsappController: _guardianWhatsappController,
                      sameWhatsapp: _guardianWhatsappSame,
                      onSameWhatsappChanged: (value) {
                        setState(() {
                          _guardianWhatsappSame = value;
                          if (value) _syncGuardianWhatsapp();
                        });
                      },
                    ),
'@ 'page guardian call'

$familyPattern = '(?s)  Widget _familyInformationRow\(\{.*?\n  String\? _validateCnic'
if (-not [regex]::IsMatch($page,$familyPattern)) {
  throw 'ANCHOR ERROR: family information widget'
}

$familyReplacement = @'
  Widget _familyInformationRow({
    required bool isDesktop,
    required String relation,
    required TextEditingController nameController,
    required TextEditingController cnicController,
    required TextEditingController phoneController,
    required TextEditingController whatsappController,
    required bool sameWhatsapp,
    required ValueChanged<bool> onSameWhatsappChanged,
    bool nameRequired = false,
  }) {
    final nameField = _textField(
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
    );

    final cnicField = _textField(
      controller: cnicController,
      label: '$relation CNIC #',
      icon: Icons.credit_card_outlined,
      keyboardType: TextInputType.number,
      validator: _validateCnic,
    );

    final phoneField = _textField(
      controller: phoneController,
      label: '$relation Mobile Number',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: _validateMobile,
    );

    final whatsappField = _textField(
      controller: whatsappController,
      label: '$relation WhatsApp Number',
      icon: Icons.chat_outlined,
      keyboardType: TextInputType.phone,
      readOnly: sameWhatsapp,
      validator: _validateMobile,
    );

    final whatsappSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            '$relation mobile number is also WhatsApp number',
          ),
          value: sameWhatsapp,
          onChanged: (value) {
            onSameWhatsappChanged(value ?? false);
          },
        ),
        whatsappField,
      ],
    );

    if (!isDesktop) {
      return Column(
        children: [
          nameField,
          const SizedBox(height: 16),
          cnicField,
          const SizedBox(height: 16),
          phoneField,
          const SizedBox(height: 8),
          whatsappSection,
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: nameField),
            const SizedBox(width: 20),
            Expanded(child: cnicField),
            const SizedBox(width: 20),
            Expanded(child: phoneField),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 360,
            child: whatsappSection,
          ),
        ),
      ],
    );
  }

  String? _validateCnic
'@

$page = [regex]::Replace($page,$familyPattern,$familyReplacement,1)
WriteText $pageFile $page

& dart format $entityFile $modelFile $pageFile
if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze lib/features/students --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) {
  throw "STUDENT WHATSAPP ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Student WhatsApp number enhancement completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Added separate Father, Mother, and Guardian WhatsApp numbers with Same-as-Mobile checkboxes.' -ForegroundColor Yellow
Write-Host 'Existing records remain compatible; missing WhatsApp numbers fall back to mobile numbers.' -ForegroundColor Yellow
