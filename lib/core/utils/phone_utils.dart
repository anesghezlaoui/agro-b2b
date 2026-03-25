/// Garde uniquement les chiffres (pour API login / inscription).
String digitsOnlyPhone(String input) =>
    input.replaceAll(RegExp(r'\D'), '');

bool isValidLocalPhone10(String input) =>
    RegExp(r'^\d{10}$').hasMatch(digitsOnlyPhone(input));
