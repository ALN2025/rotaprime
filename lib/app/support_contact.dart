/// Contato de suporte DEV ALN (WhatsApp).
class SupportContact {
  SupportContact._();

  /// E.164 sem símbolos: +55 54 99137-6738
  static const whatsAppDigits = '5554991376738';

  static const whatsAppDisplay = '+55 54 99137-6738';

  static Uri whatsAppUri({String? prefilledMessage}) {
    final base = Uri.parse('https://wa.me/$whatsAppDigits');
    if (prefilledMessage == null || prefilledMessage.trim().isEmpty) {
      return base;
    }
    return base.replace(
      queryParameters: {'text': prefilledMessage.trim()},
    );
  }
}
