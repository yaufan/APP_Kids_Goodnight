import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/ended/ended_screen.dart';
import '../features/evening/evening_screen.dart';
import '../features/lullaby/lullaby_view.dart';
import '../features/parent/parent_gate.dart';
import '../features/parent/parent_screen.dart';
import 'strings.dart';
import 'theme.dart';

/// The pages: the evening (`/`), the lullaby alone (`/lullaby`: 「只要搖籃曲」,
/// or opened again within an hour of good night), the end (`/ended`, where
/// iOS stays because an app cannot close itself there) and parent mode.
final routerProvider = Provider<GoRouter>((ref) {
  bool lullabyOnly() {
    final g = ref.read(gameProvider);
    return g.settings.lullabyOnly || g.locked(ref.read(clockProvider)());
  }

  final router = GoRouter(
    initialLocation: lullabyOnly() ? '/lullaby' : '/',
    // Always start here, whatever page another app asks the phone to open.
    overridePlatformDefaultLocation: true,
    redirect: (_, state) {
      final at = state.matchedLocation;
      if (at == '/parent' && !ParentPass.take()) return lullabyOnly() ? '/lullaby' : '/';
      if (at == '/' && lullabyOnly()) return '/lullaby';
      return null;
    },
    onException: (_, _, router) => router.go('/'),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const EveningScreen()),
      GoRoute(path: '/lullaby', builder: (_, _) => const LullabyOnlyScreen()),
      GoRoute(path: '/ended', builder: (_, _) => const EndedScreen()),
      GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class GoodnightApp extends ConsumerWidget {
  const GoodnightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider.select((g) => g.settings));
    ref.read(soundsProvider)
      ..volume = s.volume
      ..effects = s.sounds;
    ref.read(voiceProvider).slow = s.slowVoice;
    return MaterialApp.router(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: NightTheme.dark(),
      locale: const Locale('zh', 'TW'),
      supportedLocales: const [Locale('zh', 'TW')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
