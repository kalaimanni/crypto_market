import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';


class AuthNotifier extends Notifier<bool> {
  static const _user = 'crypto';
  static const _pass = '12345';
  static const _key = 'logged_in';

  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(_key) ?? false;

  Future<bool> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 600)); // simulate request
    final ok = username.trim() == _user && password == _pass;
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


// import 'dart:convert';

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;

// import '../../../core/providers.dart';


// const String kApiBaseUrl = 'http://localhost:3000';

// class AuthNotifier extends Notifier<bool> {
//   static const _key = 'logged_in';

//   @override
//   bool build() => ref.watch(sharedPrefsProvider).getBool(_key) ?? false;

//   Future<bool> login(String username, String password) async {
//     try {
//       final res = await http
//           .post(
//             Uri.parse('$kApiBaseUrl/login'),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({'username': username.trim(), 'password': password}),
//           )
//           .timeout(const Duration(seconds: 10));

//       final ok = res.statusCode == 200 && (jsonDecode(res.body)['success'] == true);
//       if (ok) {
//         await ref.read(sharedPrefsProvider).setBool(_key, true);
//         state = true;
//       }
//       return ok;
//     } catch (_) {
//       // Network error / server down
//       return false;
//     }
//   }

//   Future<void> logout() async {
//     await ref.read(sharedPrefsProvider).setBool(_key, false);
//     state = false;
//   }
// }

// final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);