import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/previews/design_previews.dart';

/// Run with: flutter run -t lib/previews/preview_main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();

  runApp(
    DevicePreview(
      enabled: true,
      defaultDevice: Devices.android.samsungGalaxyA50,
      builder: (context) => ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => Future.value(db)),
          firebaseInitProvider.overrideWith((ref) async {}),
        ],
        child: MaterialApp(
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          home: const PreviewGallery(),
        ),
      ),
    ),
  );
}

class PreviewGallery extends StatelessWidget {
  const PreviewGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final frames = <Widget>[
      const HomePreview(tier: DeviceTier.high),
      const HomePreview(tier: DeviceTier.low),
      const PostItemPreview(),
      const PostGigPreview(),
      const InboxPreview(),
      const ChatPreview(),
      const ProfilePreview(initialTab: 0),
      const ProfilePreview(initialTab: 1),
      const ProfilePreview(initialTab: 2),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Design Previews (360×800)')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: frames.length,
        separatorBuilder: (_, _) => const SizedBox(height: 24),
        itemBuilder: (context, index) => frames[index],
      ),
    );
  }
}
