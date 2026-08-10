import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/school_settings_entity.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class BrandingSettingsPage extends StatelessWidget {
  const BrandingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBloc>(
      create: (_) => sl<SettingsBloc>()..add(const LoadSettings()),
      child: const _BrandingSettingsView(),
    );
  }
}

class _BrandingSettingsView extends StatefulWidget {
  const _BrandingSettingsView();

  @override
  State<_BrandingSettingsView> createState() => _BrandingSettingsViewState();
}

class _BrandingSettingsViewState extends State<_BrandingSettingsView> {
  final _formKey = GlobalKey<FormState>();

  final _schoolNameController = TextEditingController();

  final _schoolLogoController = TextEditingController();

  final _principalNameController = TextEditingController();

  final _principalDesignationController = TextEditingController();

  final _principalSignatureController = TextEditingController();

  final _schoolStampController = TextEditingController();

  bool _initialized = false;

  bool _isUploadingLogo = false;
  bool _isUploadingSignature = false;
  bool _isUploadingStamp = false;
  String _principalSignatureData = '';
  String _schoolStampData = '';

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolLogoController.dispose();
    _principalNameController.dispose();
    _principalDesignationController.dispose();
    _principalSignatureController.dispose();
    _schoolStampController.dispose();

    super.dispose();
  }

  void _fill(SchoolSettingsEntity settings) {
    if (_initialized) {
      return;
    }

    _schoolNameController.text = settings.schoolName;

    _schoolLogoController.text = settings.logoUrl;

    _principalNameController.text = settings.principalName;

    _principalDesignationController.text = settings.principalDesignation;

    _principalSignatureController.text = settings.principalSignatureUrl;
    _principalSignatureData = settings.principalSignatureData;

    _schoolStampController.text = settings.schoolStampUrl;
    _schoolStampData = settings.schoolStampData;

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsLoaded && state.message != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message!)));
            }

            if (state is SettingsFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is SettingsInitial || state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SettingsFailure) {
              return _LoadFailure(
                message: state.message,
                onRetry: () {
                  context.read<SettingsBloc>().add(const LoadSettings());
                },
              );
            }

            final loaded = state as SettingsLoaded;

            _fill(loaded.settings);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PageHeader(),

                        const SizedBox(height: 24),

                        _buildSchoolIdentityCard(),

                        const SizedBox(height: 18),

                        _buildPrincipalCard(),

                        const SizedBox(height: 18),

                        _buildSignatureCard(),

                        const SizedBox(height: 18),

                        _buildStampCard(),

                        const SizedBox(height: 24),

                        _buildSaveButton(loaded),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSchoolIdentityCard() {
    return _SettingsCard(
      title: 'School Identity',
      subtitle: 'School name and logo used throughout the ERP.',
      icon: Icons.school_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth = constraints.maxWidth >= 760
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller: _schoolNameController,
                  decoration: const InputDecoration(
                    labelText: 'School Name',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'School name is required.';
                    }

                    return null;
                  },
                ),
              ),

              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller: _schoolLogoController,
                  decoration: const InputDecoration(
                    labelText: 'School Logo URL',
                    prefixIcon: Icon(Icons.image_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),

              SizedBox(
                width: fieldWidth,
                child: OutlinedButton.icon(
                  onPressed: _isUploadingLogo ? null : _uploadSchoolLogo,
                  icon: _isUploadingLogo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _isUploadingLogo ? 'Uploading...' : 'Upload School Logo',
                  ),
                ),
              ),

              if (_schoolLogoController.text.trim().isNotEmpty)
                SizedBox(
                  width: fieldWidth,
                  child: Column(
                    children: [
                      _ImagePreview(
                        title: 'Current School Logo',
                        imageUrl: _schoolLogoController.text.trim(),
                        height: 120,
                      ),

                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _schoolLogoController.clear();
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove Logo'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrincipalCard() {
    return _SettingsCard(
      title: 'Principal',
      subtitle: 'Principal information used on official documents and cards.',
      icon: Icons.person_outline,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth = constraints.maxWidth >= 760
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller: _principalNameController,
                  decoration: const InputDecoration(
                    labelText: 'Principal Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller: _principalDesignationController,
                  decoration: const InputDecoration(
                    labelText: 'Principal Designation',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSignatureCard() {
    return _SettingsCard(
      title: 'Principal Signature',
      subtitle:
          'Upload a scanned signature or draw a signature on a touch screen.',
      icon: Icons.draw_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _principalSignatureController,
            decoration: const InputDecoration(
              labelText: 'Principal Signature URL',
              prefixIcon: Icon(Icons.draw_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _isUploadingSignature
                    ? null
                    : _uploadPrincipalSignature,
                icon: _isUploadingSignature
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
                label: Text(
                  _isUploadingSignature ? 'Uploading...' : 'Upload Signature',
                ),
              ),

              OutlinedButton.icon(
                onPressed: _isUploadingSignature
                    ? null
                    : _drawPrincipalSignature,
                icon: const Icon(Icons.draw_outlined),
                label: const Text('Draw Signature'),
              ),

              if (_principalSignatureController.text.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _principalSignatureController.clear();
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Signature'),
                ),
            ],
          ),

          if (_principalSignatureController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 18),

            _ImagePreview(
              title: 'Current Principal Signature',
              imageUrl: _principalSignatureController.text.trim(),
              height: 120,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStampCard() {
    return _SettingsCard(
      title: 'School Official Stamp',
      subtitle:
          'Official school stamp available for certificates and other approved documents.',
      icon: Icons.verified_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _schoolStampController,
            decoration: const InputDecoration(
              labelText: 'School Stamp URL',
              prefixIcon: Icon(Icons.verified_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _isUploadingStamp ? null : _uploadSchoolStamp,
                icon: _isUploadingStamp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
                label: Text(
                  _isUploadingStamp ? 'Uploading...' : 'Upload School Stamp',
                ),
              ),

              if (_schoolStampController.text.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _schoolStampController.clear();
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Stamp'),
                ),
            ],
          ),

          if (_schoolStampController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 18),

            _ImagePreview(
              title: 'Current School Stamp',
              imageUrl: _schoolStampController.text.trim(),
              height: 150,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton(SettingsLoaded loaded) {
    final uploading =
        _isUploadingLogo || _isUploadingSignature || _isUploadingStamp;

    return FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: _brandBlue),
      onPressed: loaded.isSaving || uploading
          ? null
          : () => _save(loaded.settings),
      icon: loaded.isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined),
      label: Text(loaded.isSaving ? 'Saving...' : 'Save Branding'),
    );
  }

  Future<PlatformFile?> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.single;
  }

  String _contentType(String extension) {
    if (extension == 'png') {
      return 'image/png';
    }

    return 'image/jpeg';
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('school')
        .child('branding')
        .child(fileName);

    await storageRef.putData(bytes, SettableMetadata(contentType: contentType));

    return storageRef.getDownloadURL();
  }

  Future<void> _uploadSchoolLogo() async {
    try {
      final file = await _pickImage();

      if (file == null) {
        return;
      }

      if (file.bytes == null) {
        throw Exception('Unable to read selected image.');
      }

      setState(() {
        _isUploadingLogo = true;
      });

      final extension = file.extension?.toLowerCase() ?? 'png';

      final downloadUrl = await _uploadBytes(
        bytes: file.bytes!,
        fileName: 'school_logo.$extension',
        contentType: _contentType(extension),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _schoolLogoController.text = downloadUrl;

        _isUploadingLogo = false;
      });

      _showMessage('School logo uploaded successfully.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingLogo = false;
      });

      _showMessage('Logo upload failed: $e');
    }
  }

  Future<void> _uploadPrincipalSignature() async {
    try {
      final file = await _pickImage();

      if (file == null) {
        return;
      }

      if (file.bytes == null) {
        throw Exception('Unable to read selected signature.');
      }

      setState(() {
        _isUploadingSignature = true;
      });

      final extension = file.extension?.toLowerCase() ?? 'png';

      final downloadUrl = await _uploadBytes(
        bytes: file.bytes!,
        fileName: 'principal_signature.$extension',
        contentType: _contentType(extension),
      );
      final compactBytes = await _compactSignatureBytes(file.bytes!);

      if (!mounted) {
        return;
      }

      setState(() {
        _principalSignatureController.text = downloadUrl;
        _principalSignatureData = base64Encode(compactBytes);

        _isUploadingSignature = false;
      });

      _showMessage('Principal signature uploaded successfully.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingSignature = false;
      });

      _showMessage('Signature upload failed: $e');
    }
  }

  Future<void> _uploadSchoolStamp() async {
    try {
      final file = await _pickImage();

      if (file == null) {
        return;
      }

      if (file.bytes == null) {
        throw Exception('Unable to read selected stamp.');
      }

      setState(() {
        _isUploadingStamp = true;
      });

      final extension = file.extension?.toLowerCase() ?? 'png';

      final downloadUrl = await _uploadBytes(
        bytes: file.bytes!,
        fileName: 'school_stamp.$extension',
        contentType: _contentType(extension),
      );
      final compactBytes = await _compactSignatureBytes(file.bytes!);

      if (!mounted) {
        return;
      }

      setState(() {
        _schoolStampController.text = downloadUrl;
        _schoolStampData = base64Encode(compactBytes);

        _isUploadingStamp = false;
      });

      _showMessage('School stamp uploaded successfully.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingStamp = false;
      });

      _showMessage('School stamp upload failed: $e');
    }
  }

  Future<void> _drawPrincipalSignature() async {
    final bytes = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const _SignaturePadDialog();
      },
    );

    if (bytes == null) {
      return;
    }

    try {
      setState(() {
        _isUploadingSignature = true;
      });

      final downloadUrl = await _uploadBytes(
        bytes: bytes,
        fileName: 'principal_signature.png',
        contentType: 'image/png',
      );
      final compactBytes = await _compactSignatureBytes(bytes);

      if (!mounted) {
        return;
      }

      setState(() {
        _principalSignatureController.text = downloadUrl;
        _principalSignatureData = base64Encode(compactBytes);

        _isUploadingSignature = false;
      });

      _showMessage('Principal signature saved successfully.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingSignature = false;
      });

      _showMessage('Signature save failed: $e');
    }
  }

  Future<Uint8List> _compactSignatureBytes(Uint8List source) async {
    final sourceCodec = await ui.instantiateImageCodec(source);
    final sourceFrame = await sourceCodec.getNextFrame();
    final sourceWidth = sourceFrame.image.width;
    final sourceHeight = sourceFrame.image.height;
    sourceFrame.image.dispose();
    sourceCodec.dispose();

    final scale = [
      500 / sourceWidth,
      200 / sourceHeight,
      1.0,
    ].reduce((value, next) => value < next ? value : next);
    final targetWidth = (sourceWidth * scale).round().clamp(1, 500);
    final targetHeight = (sourceHeight * scale).round().clamp(1, 200);

    final codec = await ui.instantiateImageCodec(
      source,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();

    if (data == null) {
      throw StateError('Unable to optimize signature image.');
    }
    return data.buffer.asUint8List();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(SchoolSettingsEntity current) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_principalSignatureData.length > 850000) {
      try {
        final compactBytes = await _compactSignatureBytes(
          base64Decode(_principalSignatureData),
        );
        _principalSignatureData = base64Encode(compactBytes);
      } catch (error) {
        _showMessage('Unable to optimize signature: $error');
        return;
      }
    }

    if (!mounted) return;

    final updated = current.copyWith(
      schoolName: _schoolNameController.text.trim(),

      logoUrl: _schoolLogoController.text.trim(),

      principalName: _principalNameController.text.trim(),

      principalDesignation: _principalDesignationController.text.trim().isEmpty
          ? 'Principal'
          : _principalDesignationController.text.trim(),

      principalSignatureUrl: _principalSignatureController.text.trim(),
      principalSignatureData: _principalSignatureData,

      schoolStampUrl: _schoolStampController.text.trim(),
      schoolStampData: _schoolStampData,

      updatedAt: DateTime.now(),
    );

    context.read<SettingsBloc>().add(SaveSettingsRequested(updated));
  }
}

class _SignaturePadDialog extends StatefulWidget {
  const _SignaturePadDialog();

  @override
  State<_SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<_SignaturePadDialog> {
  final GlobalKey _signatureKey = GlobalKey();

  final List<Offset?> _points = [];

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Draw Principal Signature'),
      content: SizedBox(
        width: 650,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Use mouse, touchpad or touch screen to draw the signature.',
              style: TextStyle(color: _textSecondary),
            ),

            const SizedBox(height: 14),

            RepaintBoundary(
              key: _signatureKey,
              child: Container(
                width: double.infinity,
                height: 230,
                color: Colors.white,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,

                  onPanStart: (details) {
                    setState(() {
                      _points.add(details.localPosition);
                    });
                  },

                  onPanUpdate: (details) {
                    setState(() {
                      _points.add(details.localPosition);
                    });
                  },

                  onPanEnd: (_) {
                    setState(() {
                      _points.add(null);
                    });
                  },

                  child: CustomPaint(
                    painter: _SignaturePainter(points: _points),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Draw inside the white box.',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),

        TextButton.icon(
          onPressed: _saving
              ? null
              : () {
                  setState(() {
                    _points.clear();
                  });
                },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear'),
        ),

        FilledButton.icon(
          onPressed: _saving || _points.isEmpty ? null : _saveSignature,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_saving ? 'Saving...' : 'Use Signature'),
        ),
      ],
    );
  }

  Future<void> _saveSignature() async {
    try {
      setState(() {
        _saving = true;
      });

      final boundary =
          _signatureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Unable to capture signature.');
      }

      final image = await boundary.toImage(pixelRatio: 3);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Unable to create signature image.');
      }

      final bytes = byteData.buffer.asUint8List();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(bytes);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Unable to save signature: $e')));
    }
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.points});

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return true;
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardNavigationButton(),

        SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Branding Settings',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'Manage the school identity used across cards, certificates and official documents.',
                style: TextStyle(color: _textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _brandBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _brandBlue),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          child,
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.title,
    required this.imageUrl,
    required this.height,
  });

  final String title;
  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pageBackground,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: height,
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, color: _textSecondary),

                      SizedBox(height: 6),

                      Text(
                        'Image preview unavailable',
                        style: TextStyle(color: _textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.red),

            const SizedBox(height: 12),

            const Text(
              'Unable to load Branding Settings',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
