import 'dart:convert';

import 'package:crypto/crypto.dart';

class CpfUtils {
  const CpfUtils._();

  static String onlyDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static bool isValidLength(String value) {
    return onlyDigits(value).length == 11;
  }

  static String? hash(String value) {
    final digits = onlyDigits(value);
    if (digits.length != 11) return null;
    return sha256.convert(utf8.encode(digits)).toString();
  }

  static String? last4(String value) {
    final digits = onlyDigits(value);
    if (digits.length != 11) return null;
    return digits.substring(7);
  }

  static String maskFromLast4(String? last4) {
    if (last4 == null || last4.length != 4) return 'CPF protegido';
    return '***.***.***-$last4';
  }
}
