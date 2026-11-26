import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../core/content.dart';
import '../core/providers.dart';
import '../core/screen.dart';
import '../core/voice.dart';
import '../features/parent/parent_gate.dart';
import 'strings.dart';
import 'theme.dart';

/// Where the pictures are (design/art/README.md).
abstract final class ArtPath {
  static const street = 'assets/art/street/street.svg';
  static const grille = 'assets/art/street/grille.svg';
  static String glow(Light l) => 'assets/art/street/glow_${l.name}.svg';
  static String animal(Animal a, {bool asleep = false}) => 'assets/art/animals/${a.name}_${asleep ? 'sleep' : 'awake'}.svg';
  static const moon = 'assets/art/sky/moon.svg';
  static const moonFull = 'assets/art/sky/moon_full.svg';
  static const zz = 'assets/art/sky/zz.svg';
  static const meadow = 'assets/art/sheep/meadow.svg';
  static const sheep = 'assets/art/sheep/sheep.svg';
  static const sheepSleep = 'assets/art/sheep/sheep_sleep.svg';
  static String place(String p) => 'assets/art/story/place_$p.svg';
  static String thing(String t) => 'assets/art/story/thing_$t.svg';
  static String check(Check c) => 'assets/art/checklist/${c.name}.svg';
  static String lullaby(Lullaby l) => 'assets/art/lullaby/${l.name}.svg';
  static String ui(String name) => 'assets/art/ui/$name.svg';
}

/// The colours an animal is painted in (its file has `#BODY`, `#EYE`, `#LID`).
abstract final class AnimalPaint {
  /// A black shape in a warm window.
  static const lit = {'#BODY': Color(0xFF2A2140), '#EYE': Color(0xFFFFE9B0), '#LID': Color(0xFF9AA6E0)};

  /// A soft blue sleeper in a dark window.
  static const dark = {'#BODY': Color(0xFF3E4A8A), '#EYE': Color(0xFFFFE9B0), '#LID': Color(0xFF9AA6E0)};

  /// A dark shape against the story's sky.
  static const story = {'#BODY': Color(0xFF141836), '#EYE': Color(0xFFFFE9B0), '#LID': Color(0xFF9AA6E0)};
}

/// A drawing from assets/art/ (nothing at all if it is missing).
class Art extends StatelessWidget {
  const Art(this.path, {super.key, this.fit = BoxFit.contain, this.tokens, this.alignment = Alignment.center});

  final String path;
  final BoxFit fit;
  final Alignment alignment;

  /// Placeholders to paint (`#BODY` in the animals).
  final Map<String, Color>? tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    if (t == null || t.isEmpty) {
      return SvgPicture.asset(path, fit: fit, alignment: alignment, excludeFromSemantics: true, errorBuilder: (_, _, _) => const SizedBox.expand());
    }
    return SvgPicture(TokenLoader(path, t), fit: fit, alignment: alignment, excludeFromSemantics: true, errorBuilder: (_, _, _) => const SizedBox.expand());
  }
}

/// A one-colour icon (assets/art/checklist, lullaby, ui) in [color].
class Tinted extends StatelessWidget {
  const Tinted(this.path, {super.key, required this.color, this.size});

  final String path;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(path, colorFilter: ColorFilter.mode(color, BlendMode.srcIn), excludeFromSemantics: true, errorBuilder: (_, _, _) => const SizedBox.expand()),
      );
}

/// Loads an SVG asset with its placeholder colours painted.
class TokenLoader extends SvgAssetLoader {
  const TokenLoader(super.assetName, this.tokens);

  final Map<String, Color> tokens;

  static String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  String provideSvg(ByteData? message) {
    var text = message == null ? '' : utf8.decode(message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes), allowMalformed: true);
    for (final e in tokens.entries) {
      text = text.replaceAll(e.key, hex(e.value));
    }
    return text;
  }

  int get _tokensHash => Object.hashAll([for (final e in tokens.entries) e.key, for (final e in tokens.entries) e.value.toARGB32()]);

  @override
  SvgCacheKey cacheKey(BuildContext? context) => SvgCacheKey(keyData: Object.hash(assetName, _tokensHash), colorMapper: colorMapper, theme: getTheme(context));

  @override
  bool operator ==(Object other) => other is TokenLoader && other.assetName == assetName && other._tokensHash == _tokensHash;

  @override
  int get hashCode => Object.hash(assetName, _tokensHash);
}

/// The night sky: a soft gradient and slowly breathing stars (never
/// flashing). [stars] is how many show, 0 to 1.
class NightSky extends StatefulWidget {
  const NightSky({super.key, this.top = Night.sky, this.bottom = Night.skyLow, this.stars = 1, this.child});

  final Color top;
  final Color bottom;
  final double stars;
  final Widget? child;

  @override
  State<NightSky> createState() => _NightSkyState();
}

class _NightSkyState extends State<NightSky> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [widget.top, widget.bottom])),
        child: CustomPaint(painter: _Stars(_c, widget.stars), child: widget.child ?? const SizedBox.expand()),
      );
}

class _Stars extends CustomPainter {
  _Stars(this.time, this.amount) : super(repaint: time);

  final Animation<double> time;
  final double amount;

  static final _stars = () {
    final r = math.Random(7);
    return [for (var i = 0; i < 70; i++) (r.nextDouble(), r.nextDouble() * 0.62, 0.6 + r.nextDouble() * 1.4, r.nextDouble(), r.nextDouble())];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final (x, y, rad, phase, order) in _stars) {
      if (order > amount) continue;
      final a = 0.45 + 0.35 * math.sin((time.value + phase) * 2 * math.pi);
      p.color = Night.warm.withValues(alpha: a.clamp(0, 1) * 0.9);
      canvas.drawCircle(Offset(x * size.width, y * size.height), rad, p);
    }
  }

  @override
  bool shouldRepaint(_Stars old) => old.amount != amount;
}

/// A gentle drift up and down (or a slow sway with [turn]).
class Drift extends StatefulWidget {
  const Drift({super.key, required this.child, this.phase = 0, this.amount = 4, this.turn = 0, this.seconds = 4});

  final Widget child;
  final double phase;
  final double amount;

  /// Sways by this many radians instead of moving.
  final double turn;
  final int seconds;

  @override
  State<Drift> createState() => _DriftState();
}

class _DriftState extends State<Drift> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final s = math.sin((_c.value + widget.phase) * 2 * math.pi);
          if (widget.turn != 0) return Transform.rotate(angle: s * widget.turn, alignment: Alignment.bottomCenter, child: child);
          return Transform.translate(offset: Offset(0, s * widget.amount), child: child);
        },
        child: widget.child,
      );
}

/// The little 'z z' over a sleeper.
class Zz extends StatelessWidget {
  const Zz({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) => Drift(amount: size * 0.12, seconds: 5, child: SizedBox(width: size, height: size, child: const Art(ArtPath.zz)));
}

/// The faint 「×」 in the corner, for grown-ups: the gate, then parent mode.
class ParentCorner extends StatelessWidget {
  const ParentCorner({super.key, this.faint = false});

  /// Even fainter (on the black lullaby screen).
  final bool faint;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Semantics(
              container: true,
              button: true,
              label: Strings.parent,
              excludeSemantics: true,
              onTap: () => openParent(context),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => openParent(context),
                child: Container(
                  key: const ValueKey('parent-corner'),
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: faint ? 0.03 : 0.08)),
                  child: Tinted(ArtPath.ui('close'), color: Night.soft.withValues(alpha: faint ? 0.18 : 0.6), size: 18),
                ),
              ),
            ),
          ),
        ),
      );
}

/// The gate, then parent mode on top of what is on screen.
Future<void> openParent(BuildContext context) async {
  if (!await showParentGate(context) || !context.mounted) return;
  await context.push('/parent');
}

/// The parent's extra darkness over the children's screens (a black layer;
/// no system permission).
class DimLayer extends ConsumerWidget {
  const DimLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dim = ref.watch(gameProvider.select((g) => g.settings.dim));
    if (dim <= 0) return const SizedBox.shrink();
    return IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: dim), child: const SizedBox.expand()));
  }
}

/// A soft rounded button on the night (the story's buttons, the lullaby's choices).
class SoftButton extends ConsumerWidget {
  const SoftButton({super.key, required this.label, this.icon, this.onTap, this.selected = false, this.height = 56, this.fontSize = 20, this.locked = false});

  final String label;
  final String? icon;
  final VoidCallback? onTap;
  final bool selected;
  final double height;
  final double fontSize;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = selected ? Night.warm : Night.soft;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                ref.read(soundsProvider).play('tap');
                onTap!();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: height,
          padding: EdgeInsets.symmetric(horizontal: height * 0.4),
          decoration: BoxDecoration(
            color: selected ? Night.cardEdge : Night.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: selected ? Night.warm.withValues(alpha: 0.7) : Night.cardEdge, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Tinted(icon!, color: color, size: height * 0.45), SizedBox(width: height * 0.15)],
            Text(label, style: TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w700)),
            if (locked) ...[const SizedBox(width: 6), Tinted(ArtPath.ui('lock'), color: Night.faint, size: fontSize * 0.8)],
          ]),
        ),
      ),
    );
  }
}

/// A title at the top of a children's screen: small and faint.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, color: Night.soft, letterSpacing: 2)),
      );
}

/// Words grow a little on a tablet (the children's screens only).
class KidScale extends StatelessWidget {
  const KidScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final k = (mq.size.shortestSide / 400).clamp(1.0, 1.5);
    return MediaQuery(data: mq.copyWith(textScaler: TextScaler.linear(k)), child: child);
  }
}

/// Cross-fades one whole screen into the next (both fill the space).
Widget fillSwitcher(Widget? current, List<Widget> previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]);

/// The screen that spoke last (its WidgetRef), so a part going away hushes
/// only its own line, never the next part's first one.
Object? _speaker;

/// Says a line out loud, slowly (if the parent left the voice on). Nothing
/// is said while a parent screen is open. Completes when it has been said
/// (or cut off by the next line).
Future<void> speak(WidgetRef ref, String text) => _mayTalk(ref) ? ref.read(voiceProvider).say(text) : Future.value();

/// Reads [lines] one after another (the story), as [speak].
Future<void> readAloud(WidgetRef ref, List<String> lines) => _mayTalk(ref) ? ref.read(voiceProvider).read(lines) : Future.value();

/// The voice is on and no parent screen is open; [ref] speaks now.
bool _mayTalk(WidgetRef ref) {
  if (!ref.read(gameProvider).settings.voice || ParentIdle.showing.value > 0) return false;
  _speaker = ref;
  return true;
}

/// A part that stops its own voice when it goes away, so a line does not go
/// on over the next part (and never stops the next part's first line).
mixin HushOnLeave<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final Voice _hush;
  late final Object _me;

  @override
  void initState() {
    super.initState();
    _hush = ref.read(voiceProvider);
    _me = ref;
  }

  /// Stops this part's line (if it is the one speaking).
  void hush() {
    if (identical(_speaker, _me)) {
      _speaker = null;
      _hush.stop();
    }
  }

  @override
  void dispose() {
    hush();
    super.dispose();
  }
}

/// Runs [then] after [min], and not before the line [after] has been said
/// (at most [atMost] of waiting for it), so a slow voice is not cut off by
/// the next part; [cancel] stops it.
class Later {
  Later(Duration min, VoidCallback then, {Future<void>? after, Duration atMost = const Duration(seconds: 20)}) : _then = then {
    _timer = Timer(min, () {
      _timeUp = true;
      _fire();
    });
    if (after == null) {
      _heard = true;
    } else {
      _limit = Timer(atMost, _hear);
      after.then((_) => _hear(), onError: (_) => _hear());
    }
  }

  final VoidCallback _then;
  late final Timer _timer;
  Timer? _limit;
  var _timeUp = false, _heard = false, _over = false;

  void _hear() {
    _limit?.cancel();
    _heard = true;
    _fire();
  }

  void _fire() {
    if (_over || !_timeUp || !_heard) return;
    _over = true;
    _then();
  }

  void cancel() {
    _over = true;
    _timer.cancel();
    _limit?.cancel();
  }
}

/// The phone's back key (or back gesture) does [onBack] (null: nothing)
/// instead of closing the app in the middle of the evening.
class BackTo extends StatelessWidget {
  const BackTo({super.key, this.onBack, required this.child});

  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) onBack?.call();
        },
        child: child,
      );
}

/// Keeps the screen awake while [child]'s page is on top (awakeProvider):
/// a parent screen over it, or the page gone, and the phone may sleep.
class AwakeOnTop extends ConsumerStatefulWidget {
  const AwakeOnTop({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AwakeOnTop> createState() => _AwakeOnTopState();
}

class _AwakeOnTopState extends ConsumerState<AwakeOnTop> {
  late final Awake _awake = ref.read(awakeProvider);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _awake.set(this, ModalRoute.isCurrentOf(context) ?? true);
  }

  @override
  void dispose() {
    _awake.set(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
