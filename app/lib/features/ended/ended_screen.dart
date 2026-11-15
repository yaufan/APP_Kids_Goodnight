import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';

/// After good night. On Android the app has closed itself; iOS does not let
/// an app close, so this black page stays (only the faint corner for
/// grown-ups). The screen may sleep again.
class EndedScreen extends ConsumerStatefulWidget {
  const EndedScreen({super.key});

  @override
  ConsumerState<EndedScreen> createState() => _EndedScreenState();
}

class _EndedScreenState extends ConsumerState<EndedScreen> {
  late final Sounds _sounds = ref.read(soundsProvider);

  @override
  void initState() {
    super.initState();
    _sounds.hold(this, null);
    ref.read(screenProvider).keepOn(false);
  }

  @override
  void dispose() {
    _sounds.release(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('ended'),
    backgroundColor: Colors.black,
    body: KidScale(
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Opacity(opacity: 0.25, child: SizedBox(width: 60, height: 60, child: Art(ArtPath.moon))),
                const SizedBox(height: 10),
                Text(Strings.sleepWell, style: TextStyle(fontSize: 20, color: Night.faint.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const ParentCorner(faint: true),
        ],
      ),
    ),
  );
}
