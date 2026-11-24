import 'dart:convert';
import 'package:flutter/services.dart';

/// French texts from `assets/i18n/fr.json` (nested, same keys as apps/admin-web
/// where the screens overlap). Call [load] before `runApp`.
class Strings {
  Strings._();
  static Map<String, dynamic> _data = const {};

  static Future<void> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString('assets/i18n/fr.json');
    _data = json.decode(raw) as Map<String, dynamic>;
  }

  /// Resolves a dotted path ("search.fields.query.help"). Returns the path
  /// itself when missing so a gap is visible rather than silent.
  static String t(String path, {Map<String, Object> params = const {}}) {
    Object? node = _data;
    for (final part in path.split('.')) {
      if (node is Map<String, dynamic> && node.containsKey(part)) {
        node = node[part];
      } else {
        return path;
      }
    }
    if (node is! String) return path;
    var out = node;
    for (final e in params.entries) {
      out = out.replaceAll('{${e.key}}', '${e.value}');
    }
    return out;
  }

  /// User-facing message for a stable contract error code (sheet "Erreurs").
  static String error(String code, {int? retryAfterSeconds}) {
    if (code == 'RATE_LIMITED') {
      return retryAfterSeconds == null
          ? t('errors.RATE_LIMITED_NO_DELAY')
          : t('errors.RATE_LIMITED', params: {'seconds': retryAfterSeconds});
    }
    final key = 'errors.$code';
    final msg = t(key);
    return msg == key ? t('errors.UNKNOWN') : msg;
  }
}
