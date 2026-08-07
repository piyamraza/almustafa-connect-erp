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

class SchoolProfileSettingsPage extends StatelessWidget {
  const SchoolProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBloc>(
      create: (_) => sl<SettingsBloc>()
        ..add(
          const LoadSettings(),
        ),
      child: const _SchoolProfileSettingsView(),
    );
  }
}

class _SchoolProfileSettingsView extends StatefulWidget {
  const _SchoolProfileSettingsView();

  @override
  State<_SchoolProfileSettingsView> createState() =>
      _SchoolProfileSettingsViewState();
}

class _SchoolProfileSettingsViewState
    extends State<_SchoolProfileSettingsView> {
  final _formKey = GlobalKey<FormState>();

  final _schoolNameController = TextEditingController();
  final _tagLineController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _tagLineController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _whatsAppController.dispose();
    _emailController.dispose();
    _websiteController.dispose();

    super.dispose();
  }

  void _fill(
    SchoolSettingsEntity settings,
  ) {
    if (_initialized) {
      return;
    }

    _schoolNameController.text = settings.schoolName;
    _tagLineController.text = settings.tagLine;
    _addressController.text = settings.address;
    _cityController.text = settings.city;
    _countryController.text = settings.country;
    _phoneController.text = settings.phone;
    _whatsAppController.text = settings.whatsApp;
    _emailController.text = settings.email;
    _websiteController.text = settings.website;

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: BlocConsumer<SettingsBloc, SettingsState>(
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
                child: CircularProgressIndicator(),
              );
            }

            if (state is SettingsFailure) {
              return _LoadFailure(
                message: state.message,
                onRetry: () {
                  context.read<SettingsBloc>().add(
                        const LoadSettings(),
                      );
                },
              );
            }

            final loaded = state as SettingsLoaded;

            _fill(loaded.settings);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const _PageHeader(),
                        const SizedBox(height: 24),

                        _ProfileCard(
                          child: LayoutBuilder(
                            builder: (
                              context,
                              constraints,
                            ) {
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
                                    child: _requiredField(
                                      controller:
                                          _schoolNameController,
                                      label: 'School Name',
                                      icon:
                                          Icons.business_outlined,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _field(
                                      controller:
                                          _tagLineController,
                                      label: 'Tag Line',
                                      icon:
                                          Icons.short_text_outlined,
                                    ),
                                  ),
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: _field(
                                      controller:
                                          _addressController,
                                      label: 'Address',
                                      icon:
                                          Icons.location_on_outlined,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _field(
                                      controller:
                                          _cityController,
                                      label: 'City',
                                      icon:
                                          Icons.location_city_outlined,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _field(
                                      controller:
                                          _countryController,
                                      label: 'Country',
                                      icon:
                                          Icons.public_outlined,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _field(
                                      controller:
                                          _phoneController,
                                      label: 'Phone',
                                      icon:
                                          Icons.phone_outlined,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _field(
                                      controller:
                                          _whatsAppController,
                                      label: 'WhatsApp',
                                      icon:
                                          Icons.chat_outlined,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _field(
                                      controller:
                                          _emailController,
                                      label: 'Email',
                                      icon:
                                          Icons.email_outlined,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _field(
                                      controller:
                                          _websiteController,
                                      label: 'Website',
                                      icon:
                                          Icons.language_outlined,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        FilledButton.icon(
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
                                : 'Save School Profile',
                          ),
                        ),

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

  Widget _requiredField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required.';
        }

        return null;
      },
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _save(
    SchoolSettingsEntity current,
  ) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updated = current.copyWith(
      schoolName: _schoolNameController.text.trim(),
      tagLine: _tagLineController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      country: _countryController.text.trim(),
      phone: _phoneController.text.trim(),
      whatsApp: _whatsAppController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      updatedAt: DateTime.now(),
    );

    context.read<SettingsBloc>().add(
          SaveSettingsRequested(
            updated,
          ),
        );
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
                'School Profile',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage general school information used throughout the ERP.',
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _borderColor,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _LoadFailure extends StatelessWidget {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 44,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load School Profile',
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
              style: const TextStyle(
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}