/// Coordonnées support (validation compte, questions).
class SupportContact {
  const SupportContact._();

  static const String phoneDisplay = '+213 550 30 54 71';

  /// `Uri(…)` n’est pas une constante de compilation → `final` + parse.
  static final Uri phoneUri = Uri.parse('tel:+213550305471');
  static final Uri whatsappUri = Uri.parse('https://wa.me/213550305471');
}
