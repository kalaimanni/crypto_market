import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());
final apiClientProvider = Provider<ApiClient>((_) => ApiClient());
