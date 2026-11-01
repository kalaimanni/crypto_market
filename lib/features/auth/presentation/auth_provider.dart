// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../core/providers.dart';


// class AuthNotifier extends Notifier<bool> {
//   static const _user = 'crypto';
//   static const _pass = '12345';
//   static const _key = 'logged_in';

//   @override
//   bool build() => ref.watch(sharedPrefsProvider).getBool(_key) ?? false;

//   Future<bool> login(String username, String password) async {
//     await Future<void>.delayed(const Duration(milliseconds: 600)); // simulate request
//     final ok = username.trim() == _user && password == _pass;
//     if (ok) {
//       await ref.read(sharedPrefsProvider).setBool(_key, true);
//       state = true;
//     }
//     return ok;
//   }

//   Future<void> logout() async {
//     await ref.read(sharedPrefsProvider).setBool(_key, false);
//     state = false;
//   }
// }

// final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/providers.dart';

/// Works on both web and mobile.
/// - Web / iOS simulator / desktop: localhost
/// - Android emulator: 10.0.2.2 (localhost there means the emulator itself)
String get kApiBaseUrl {
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

class AuthNotifier extends Notifier<bool> {
  static const _key = 'logged_in';

  // Static fallback, used ONLY when the Node server cannot be reached
  static const _fallbackUser = 'crypto';
  static const _fallbackPass = '12345';

  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(_key) ?? false;

  Future<bool> login(String username, String password) async {
    final user = username.trim();
    bool ok;

    try {
      final res = await http
          .post(
            Uri.parse('$kApiBaseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': user, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

      // Server answered -> trust the server
      ok = res.statusCode == 200 && (jsonDecode(res.body)['success'] == true);
    } catch (_) {
      // Server down / no network / timeout -> use static check
      ok = user == _fallbackUser && password == _fallbackPass;
    }

    if (ok) {
      await ref.read(sharedPrefsProvider).setBool(_key, true);
      state = true;
    }
    return ok;
  }

  Future<void> logout() async {
    await ref.read(sharedPrefsProvider).setBool(_key, false);
    state = false;
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);