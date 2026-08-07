import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class SystemPrefixesSettingsPage
    extends StatefulWidget {
  const SystemPrefixesSettingsPage({
    super.key,
  });

  @override
  State<SystemPrefixesSettingsPage>
      createState() =>
          _SystemPrefixesSettingsPageState();
}

class _SystemPrefixesSettingsPageState
    extends State<SystemPrefixesSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _admissionPrefixController =
      TextEditingController(text: 'AMS');

  final _rollPrefixController =
      TextEditingController();

  final _receiptPrefixController =
      TextEditingController(text: 'REC');

  @override
  void dispose() {
    _admissionPrefixController.dispose();
    _rollPrefixController.dispose();
    _receiptPrefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1000,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const _PrefixesHeader(),
                    const SizedBox(height: 24),
                    _PrefixesCard(
                      child: LayoutBuilder(
                        builder:
                            (context, constraints) {
                          final fieldWidth =
                              constraints.maxWidth >=
                                      760
                                  ? (constraints
                                              .maxWidth -
                                          16) /
                                      2
                                  : constraints
                                      .maxWidth;

                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width:
                                    fieldWidth,
                                child:
                                    TextFormField(
                                  controller:
                                      _admissionPrefixController,
                                  decoration:
                                      const InputDecoration(
                                    labelText:
                                        'Admission Prefix',
                                    prefixIcon:
                                        Icon(
                                      Icons
                                          .person_add_alt_outlined,
                                    ),
                                    border:
                                        OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width:
                                    fieldWidth,
                                child:
                                    TextFormField(
                                  controller:
                                      _rollPrefixController,
                                  decoration:
                                      const InputDecoration(
                                    labelText:
                                        'Roll Number Prefix',
                                    prefixIcon:
                                        Icon(
                                      Icons
                                          .confirmation_number_outlined,
                                    ),
                                    border:
                                        OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width:
                                    fieldWidth,
                                child:
                                    TextFormField(
                                  controller:
                                      _receiptPrefixController,
                                  decoration:
                                      const InputDecoration(
                                    labelText:
                                        'Receipt Prefix',
                                    prefixIcon:
                                        Icon(
                                      Icons
                                          .receipt_long_outlined,
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
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            _brandBlue,
                      ),
                      onPressed: _save,
                      icon: const Icon(
                        Icons.save_outlined,
                      ),
                      label: const Text(
                        'Save System Prefixes',
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

  void _save() {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'System Prefixes save will be connected after all Settings pages are ready.',
        ),
      ),
    );
  }
}

class _PrefixesHeader
    extends StatelessWidget {
  const _PrefixesHeader();

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
                'System Prefixes',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage prefixes used for admissions, roll numbers and receipts.',
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

class _PrefixesCard
    extends StatelessWidget {
  const _PrefixesCard({
    required this.child,
  });

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
      child: child,
    );
  }
}
