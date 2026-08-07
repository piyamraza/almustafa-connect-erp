import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class RegionalSettingsPage extends StatefulWidget {
  const RegionalSettingsPage({super.key});

  @override
  State<RegionalSettingsPage> createState() =>
      _RegionalSettingsPageState();
}

class _RegionalSettingsPageState
    extends State<RegionalSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _currencySymbolController =
      TextEditingController(text: 'Rs.');

  String _currency = 'PKR';
  String _dateFormat = 'dd-MM-yyyy';
  String _timeFormat = '12 Hour';

  @override
  void dispose() {
    _currencySymbolController.dispose();
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
                    const _RegionalHeader(),
                    const SizedBox(height: 24),
                    _RegionalCard(
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
                                    DropdownButtonFormField<
                                        String>(
                                  initialValue:
                                      _currency,
                                  decoration:
                                      const InputDecoration(
                                    labelText:
                                        'Currency',
                                    prefixIcon:
                                        Icon(
                                      Icons
                                          .payments_outlined,
                                    ),
                                    border:
                                        OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value:
                                          'PKR',
                                      child:
                                          Text(
                                        'PKR',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value:
                                          'USD',
                                      child:
                                          Text(
                                        'USD',
                                      ),
                                    ),
                                  ],
                                  onChanged:
                                      (value) {
                                    if (value !=
                                        null) {
                                      setState(
                                        () {
                                          _currency =
                                              value;
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width:
                                    fieldWidth,
                                child:
                                    TextFormField(
                                  controller:
                                      _currencySymbolController,
                                  decoration:
                                      const InputDecoration(
                                    labelText:
                                        'Currency Symbol',
                                    prefixIcon:
                                        Icon(
                                      Icons
                                          .attach_money_outlined,
                                    ),
                                    border:
                                        OutlineInputBorder(),
                                  ),
                                  validator:
                                      (value) {
                                    if (value ==
                                            null ||
                                        value
                                            .trim()
                                            .isEmpty) {
                                      return 'Currency symbol is required.';
                                    }

                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width:
                                    fieldWidth,
                                child:
                                    DropdownButtonFormField<
                                        String>(
                                  initialValue:
                                      _dateFormat,
                                  decoration:
                                      const InputDecoration(
                                    labelText:
                                        'Date Format',
                                    prefixIcon:
                                        Icon(
                                      Icons
                                          .event_outlined,
                                    ),
                                    border:
                                        OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value:
                                          'dd-MM-yyyy',
                                      child:
                                          Text(
                                        'dd-MM-yyyy',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value:
                                          'dd/MM/yyyy',
                                      child:
                                          Text(
                                        'dd/MM/yyyy',
                                      ),
                                    ),
                                  ],
                                  onChanged:
                                      (value) {
                                    if (value !=
                                        null) {
                                      setState(
                                        () {
                                          _dateFormat =
                                              value;
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width:
                                    fieldWidth,
                                child:
                                    DropdownButtonFormField<
                                        String>(
                                  initialValue:
                                      _timeFormat,
                                  decoration:
                                      const InputDecoration(
                                    labelText:
                                        'Time Format',
                                    prefixIcon:
                                        Icon(
                                      Icons
                                          .schedule_outlined,
                                    ),
                                    border:
                                        OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value:
                                          '12 Hour',
                                      child:
                                          Text(
                                        '12 Hour',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value:
                                          '24 Hour',
                                      child:
                                          Text(
                                        '24 Hour',
                                      ),
                                    ),
                                  ],
                                  onChanged:
                                      (value) {
                                    if (value !=
                                        null) {
                                      setState(
                                        () {
                                          _timeFormat =
                                              value;
                                        },
                                      );
                                    }
                                  },
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
                        'Save Regional Settings',
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
          'Regional Settings save will be connected after all Settings pages are ready.',
        ),
      ),
    );
  }
}

class _RegionalHeader
    extends StatelessWidget {
  const _RegionalHeader();

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
                'Regional Settings',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Configure currency, date format and time format.',
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

class _RegionalCard
    extends StatelessWidget {
  const _RegionalCard({
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
