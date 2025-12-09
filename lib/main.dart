import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nadimu/routes/app_pages.dart';
import 'package:nadimu/themes/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://wxdbbfevtygqehrtizyt.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind4ZGJiZmV2dHlncWVocnRpenl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxOTI1MTcsImV4cCI6MjA4MDc2ODUxN30.example_anon_key_here', // GANTI dengan anon key yang benar
    );
    
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
  }
  
  runApp(const MyApp());
}

// Get a reference to your Supabase client (Global instance)
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Nadimu',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Support light/dark based on system
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}