import 'package:flutter/material.dart';
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
      create: (_) => sl<SettingsBloc>()
        ..add(
          const LoadSettings(),
        ),
      child: const _BrandingSettingsView(),
    );
  }
}

class _BrandingSettingsView extends StatefulWidget {
  const _BrandingSettingsView();

  @override
  State<_BrandingSettingsView> createState() =>
      _BrandingSettingsViewState();
}

class _BrandingSettingsViewState
    extends State<_BrandingSettingsView> {
  final _formKey = GlobalKey<FormState>();

  final _schoolNameController =
      TextEditingController();

  final _schoolLogoController =
      TextEditingController();

  final _principalNameController =
      TextEditingController();

  final _principalDesignationController =
      TextEditingController();

  final _principalSignatureController =
      TextEditingController();

  final _schoolStampController =
      TextEditingController();

  bool _initialized = false;

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

  void _fill(
    SchoolSettingsEntity settings,
  ) {
    if (_initialized) {
      return;
    }

    _schoolNameController.text =
        settings.schoolName;

    _schoolLogoController.text =
        settings.logoUrl;

    _principalNameController.text =
        settings.principalName;

    _principalDesignationController.text =
        settings.principalDesignation;

    _principalSignatureController.text =
        settings.principalSignatureUrl;

    _schoolStampController.text =
        settings.schoolStampUrl;

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: BlocConsumer<
            SettingsBloc,
            SettingsState>(
          listener: (context, state) {
            if (state is SettingsLoaded &&
                state.message != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message!,
                    ),
                  ),
                );
            }

            if (state is SettingsFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                    ),
                  ),
                );
            }
          },
          builder: (context, state) {
            if (state is SettingsInitial ||
                state is SettingsLoading) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (state is SettingsFailure) {
              return _LoadFailure(
                message: state.message,
                onRetry: () {
                  context
                      .read<SettingsBloc>()
                      .add(
                        const LoadSettings(),
                      );
                },
              );
            }

            final loaded =
                state as SettingsLoaded;

            _fill(loaded.settings);

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const _PageHeader(),
                        const SizedBox(
                          height: 24,
                        ),

                        _buildSchoolIdentityCard(),

                        const SizedBox(
                          height: 18,
                        ),

                        _buildPrincipalCard(),

                        const SizedBox(
                          height: 18,
                        ),

                        _buildSignatureCard(),

                        const SizedBox(
                          height: 18,
                        ),

                        _buildStampCard(),

                        const SizedBox(
                          height: 24,
                        ),

                        _buildSaveButton(
                          loaded,
                        ),

                        const SizedBox(
                          height: 30,
                        ),
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
      subtitle:
          'School name and logo used throughout the ERP.',
      icon: Icons.school_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth =
              constraints.maxWidth >= 760
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller:
                      _schoolNameController,
                  decoration:
                      const InputDecoration(
                    labelText: 'School Name',
                    prefixIcon: Icon(
                      Icons.business_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'School name is required.';
                    }

                    return null;
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller:
                      _schoolLogoController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'School Logo URL',
                    prefixIcon: Icon(
                      Icons.image_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _comingSoon(
                      'School logo upload',
                    );
                  },
                  icon: const Icon(
                    Icons.upload_file_outlined,
                  ),
                  label: const Text(
                    'Upload School Logo',
                  ),
                ),
              ),
              if (_schoolLogoController
                  .text
                  .trim()
                  .isNotEmpty)
                SizedBox(
                  width: fieldWidth,
                  child: _ImagePreview(
                    title:
                        'Current School Logo',
                    imageUrl:
                        _schoolLogoController
                            .text
                            .trim(),
                    height: 120,
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
      subtitle:
          'Principal information used on official documents and cards.',
      icon: Icons.person_outline,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth =
              constraints.maxWidth >= 760
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller:
                      _principalNameController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Principal Name',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller:
                      _principalDesignationController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Principal Designation',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller:
                _principalSignatureController,
            decoration:
                const InputDecoration(
              labelText:
                  'Principal Signature URL',
              prefixIcon: Icon(
                Icons.draw_outlined,
              ),
              border:
                  OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _comingSoon(
                    'Scanned signature upload',
                  );
                },
                icon: const Icon(
                  Icons.upload_file_outlined,
                ),
                label: const Text(
                  'Upload Signature',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _comingSoon(
                    'On-screen signature drawing',
                  );
                },
                icon: const Icon(
                  Icons.draw_outlined,
                ),
                label: const Text(
                  'Draw Signature',
                ),
              ),
              if (_principalSignatureController
                  .text
                  .trim()
                  .isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _principalSignatureController
                          .clear();
                    });
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  label: const Text(
                    'Remove Signature',
                  ),
                ),
            ],
          ),
          if (_principalSignatureController
              .text
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 18),
            _ImagePreview(
              title:
                  'Current Principal Signature',
              imageUrl:
                  _principalSignatureController
                      .text
                      .trim(),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller:
                _schoolStampController,
            decoration:
                const InputDecoration(
              labelText:
                  'School Stamp URL',
              prefixIcon: Icon(
                Icons.verified_outlined,
              ),
              border:
                  OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _comingSoon(
                    'School stamp upload',
                  );
                },
                icon: const Icon(
                  Icons.upload_file_outlined,
                ),
                label: const Text(
                  'Upload School Stamp',
                ),
              ),
              if (_schoolStampController
                  .text
                  .trim()
                  .isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _schoolStampController
                          .clear();
                    });
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  label: const Text(
                    'Remove Stamp',
                  ),
                ),
            ],
          ),
          if (_schoolStampController
              .text
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 18),
            _ImagePreview(
              title:
                  'Current School Stamp',
              imageUrl:
                  _schoolStampController
                      .text
                      .trim(),
              height: 150,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton(
    SettingsLoaded loaded,
  ) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: _brandBlue,
      ),
      onPressed: loaded.isSaving
          ? null
          : () => _save(
                loaded.settings,
              ),
      icon: loaded.isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(
              Icons.save_outlined,
            ),
      label: Text(
        loaded.isSaving
            ? 'Saving...'
            : 'Save Branding',
      ),
    );
  }

  void _save(
    SchoolSettingsEntity current,
  ) {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final updated = current.copyWith(
      schoolName:
          _schoolNameController.text.trim(),
      logoUrl:
          _schoolLogoController.text.trim(),
      principalName:
          _principalNameController.text.trim(),
      principalDesignation:
          _principalDesignationController
                  .text
                  .trim()
                  .isEmpty
              ? 'Principal'
              : _principalDesignationController
                  .text
                  .trim(),
      principalSignatureUrl:
          _principalSignatureController
              .text
              .trim(),
      schoolStampUrl:
          _schoolStampController.text.trim(),
      updatedAt: DateTime.now(),
    );

    context.read<SettingsBloc>().add(
      SaveSettingsRequested(
        updated,
      ),
    );
  }

  void _comingSoon(
    String feature,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$feature will be connected next.',
          ),
        ),
      );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        DashboardNavigationButton(),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Branding Settings',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage the school identity used across cards, certificates and official documents.',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard
    extends StatelessWidget {
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
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _borderColor,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color: _brandBlue
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(12),
                ),
                child: Icon(
                  icon,
                  color: _brandBlue,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            _textPrimary,
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            _textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 22,
          ),
          child,
        ],
      ),
    );
  }
}

class _ImagePreview
    extends StatelessWidget {
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
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pageBackground,
        border: Border.all(
          color: _borderColor,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            height: height,
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Icon(
                        Icons
                            .broken_image_outlined,
                        color:
                            _textSecondary,
                      ),
                      SizedBox(
                        height: 6,
                      ),
                      Text(
                        'Image preview unavailable',
                        style:
                            TextStyle(
                          color:
                              _textSecondary,
                          fontSize: 12,
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
    );
  }
}

class _LoadFailure
    extends StatelessWidget {
  const _LoadFailure({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 44,
              color: Colors.red,
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'Unable to load Branding Settings',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    _textSecondary,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}