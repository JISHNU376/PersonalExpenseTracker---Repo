import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://jmodlqcjsflehhguixnn.supabase.co',
      anonKey: 'sb_publishable_0P95lJTX63ZZVKFBjhAPmQ_SzXOfyXu',
    );
  }
}
