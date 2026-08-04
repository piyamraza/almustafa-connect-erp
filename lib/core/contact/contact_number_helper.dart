class ContactNumberHelper {
  const ContactNumberHelper._();

  static String normalizeNumber(String value) =>
      value.replaceAll(RegExp(r'[^0-9+]'), '').trim();

  static String preferredWhatsAppNumber({
    required String mobileNumber,
    String? whatsappNumber,
  }) {
    final whatsapp = whatsappNumber?.trim() ?? '';
    return normalizeNumber(whatsapp.isNotEmpty ? whatsapp : mobileNumber);
  }

  static bool areSameNumbers(String mobileNumber, String whatsappNumber) {
    final mobile = normalizeNumber(mobileNumber);
    final whatsapp = normalizeNumber(whatsappNumber);
    return mobile.isNotEmpty && mobile == whatsapp;
  }
}
