import 'package:flutter/material.dart';

class ContactInfoField extends StatefulWidget {
  const ContactInfoField({
    required this.mobileController,
    required this.whatsappController,
    required this.sameAsMobile,
    required this.onSameAsMobileChanged,
    super.key,
    this.mobileLabel = 'Mobile Number',
    this.whatsappLabel = 'WhatsApp Number',
    this.mobileRequired = false,
    this.whatsappRequired = false,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.spacing = 12,
    this.breakpoint = 620,
  });

  final TextEditingController mobileController;
  final TextEditingController whatsappController;
  final bool sameAsMobile;
  final ValueChanged<bool> onSameAsMobileChanged;
  final String mobileLabel;
  final String whatsappLabel;
  final bool mobileRequired;
  final bool whatsappRequired;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool readOnly;
  final double spacing;
  final double breakpoint;

  @override
  State<ContactInfoField> createState() => _ContactInfoFieldState();
}

class _ContactInfoFieldState extends State<ContactInfoField> {
  @override
  void initState() {
    super.initState();
    widget.mobileController.addListener(_syncWhatsApp);
    _syncWhatsApp();
  }

  @override
  void didUpdateWidget(covariant ContactInfoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mobileController != widget.mobileController) {
      oldWidget.mobileController.removeListener(_syncWhatsApp);
      widget.mobileController.addListener(_syncWhatsApp);
    }
    if (!oldWidget.sameAsMobile && widget.sameAsMobile) _syncWhatsApp();
  }

  void _syncWhatsApp() {
    if (widget.sameAsMobile &&
        widget.whatsappController.text != widget.mobileController.text) {
      widget.whatsappController.text = widget.mobileController.text;
    }
  }

  String? _validate(String? value, bool required, String label) {
    if (required && (value == null || value.trim().isEmpty)) {
      return '$label is required';
    }
    if ((value ?? '').trim().isEmpty) return null;
    return widget.validator?.call(value);
  }

  @override
  void dispose() {
    widget.mobileController.removeListener(_syncWhatsApp);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = TextFormField(
      controller: widget.mobileController,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.phone,
      validator: (value) =>
          _validate(value, widget.mobileRequired, widget.mobileLabel),
      decoration: InputDecoration(
        labelText: widget.mobileLabel,
        prefixIcon: const Icon(Icons.phone),
        border: const OutlineInputBorder(),
      ),
    );
    final whatsapp = TextFormField(
      controller: widget.whatsappController,
      enabled: widget.enabled,
      readOnly: widget.readOnly || widget.sameAsMobile,
      keyboardType: TextInputType.phone,
      validator: (value) =>
          _validate(value, widget.whatsappRequired, widget.whatsappLabel),
      decoration: InputDecoration(
        labelText: widget.whatsappLabel,
        prefixIcon: const Icon(Icons.chat),
        border: const OutlineInputBorder(),
      ),
    );
    final checkbox = CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      value: widget.sameAsMobile,
      onChanged: widget.enabled && !widget.readOnly
          ? (value) {
              final checked = value ?? false;
              if (checked) {
                widget.whatsappController.text = widget.mobileController.text;
              }
              widget.onSameAsMobileChanged(checked);
            }
          : null,
      title: const Text('Mobile number is also WhatsApp number'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < widget.breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [mobile, checkbox, whatsapp],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mobile),
                SizedBox(width: widget.spacing),
                Expanded(child: whatsapp),
              ],
            ),
            checkbox,
          ],
        );
      },
    );
  }
}
