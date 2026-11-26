import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../core/game.dart';
import '../../core/providers.dart';

/// A question a grown-up answers easily but a 2 to 5 year old cannot read:
/// the numbers are written out in Chinese characters (as in the sibling apps).
class ParentGateChallenge {
  ParentGateChallenge(this.a, this.b);

  factory ParentGateChallenge.random([math.Random? random]) {
    final r = random ?? math.Random();
    return ParentGateChallenge(3 + r.nextInt(7), 3 + r.nextInt(7));
  }

  final int a;
  final int b;

  static const _digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

  String get question => Strings.gateQuestion(_digits[a], _digits[b]);

  int get answer => a + b;

  bool check(String typed) => int.tryParse(typed.trim()) == answer;
}

/// Completes with true only for a right answer.
Future<bool> showParentGate(BuildContext context) async {
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ParentGatePage()),
  );
  if (ok ?? false) ParentPass.grant();
  return ok ?? false;
}

/// Parent mode opens only right after the gate was answered: the router
/// takes the pass, so nothing else (a link from another app) can open it.
abstract final class ParentPass {
  static var _open = false;

  static void grant() => _open = true;

  /// Whether parent mode may open now (once per right answer).
  static bool take() {
    final open = _open;
    _open = false;
    return open;
  }
}

/// Parent screens close by themselves (the gate, parent mode): after [idle]
/// without a touch, or as soon as the app goes to the background, [onClose]
/// takes the phone back to the evening and the pass from the gate is used
/// up, so a child who opens the app again meets the gate again. A gate a
/// child opened with the faint 「×」 (or a parent who fell asleep in parent
/// mode) never holds the evening up for long.
class ParentIdle extends StatefulWidget {
  const ParentIdle({super.key, required this.onClose, required this.child});

  static const idle = Duration(minutes: 5);

  /// How many parent screens are open (nothing is said meanwhile).
  static final showing = ValueNotifier<int>(0);

  final VoidCallback onClose;
  final Widget child;

  @override
  State<ParentIdle> createState() => _ParentIdleState();
}

class _ParentIdleState extends State<ParentIdle> {
  Timer? _timer;
  AppLifecycleListener? _life;
  var _closed = false;

  @override
  void initState() {
    super.initState();
    ParentIdle.showing.value++;
    _touched();
    _life = AppLifecycleListener(onHide: _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _life?.dispose();
    ParentIdle.showing.value--;
    super.dispose();
  }

  void _touched() {
    _timer?.cancel();
    _timer = Timer(ParentIdle.idle, _close);
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    _timer?.cancel();
    ParentPass.take();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) => Listener(behavior: HitTestBehavior.translucent, onPointerDown: (_) => _touched(), child: widget.child);
}

/// Full screen, so a child cannot tap past it. Three wrong answers in a row
/// lock it for a minute, the next three for five, then fifteen (kept in the
/// file: core/game.dart GateLock). Dark, so it does not light up the
/// bedroom.
class ParentGatePage extends ConsumerStatefulWidget {
  const ParentGatePage({super.key, this.random});

  final math.Random? random;

  @override
  ConsumerState<ParentGatePage> createState() => _ParentGatePageState();
}

class _ParentGatePageState extends ConsumerState<ParentGatePage> {
  late var _challenge = ParentGateChallenge.random(widget.random);
  var _typed = '';
  var _wrong = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The wait counts down, and the keys come back when it is over.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  DateTime get _now => ref.read(clockProvider)();

  /// When the lock ends (null: not locked).
  DateTime? get _until => ref.read(gameProvider).gate.until(_now);

  void _key(String k) {
    if (_until != null) return;
    setState(() {
      _wrong = false;
      if (k == '⌫') {
        if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
        return;
      }
      if (_typed.length >= 2) return;
      _typed += k;
    });
    if (_typed.length < '${_challenge.answer}'.length) return;
    final game = ref.read(gameProvider.notifier);
    if (_challenge.check(_typed)) {
      game.change((g) => g.copyWith(gate: const GateLock()));
      Navigator.of(context).pop(true);
      return;
    }
    final now = _now;
    game.change((g) => g.copyWith(gate: g.gate.wrong(now)));
    setState(() {
      _wrong = true;
      _typed = '';
      _challenge = ParentGateChallenge.random(widget.random);
    });
  }

  @override
  Widget build(BuildContext context) => ParentIdle(onClose: () => Navigator.of(context).pop(false), child: _page(context));

  Widget _page(BuildContext context) {
    final until = _until;
    final locked = until != null;
    final wait = locked ? until.difference(_now) : Duration.zero;
    final need = '${_challenge.answer}'.length;
    Widget box(int i) => Container(
          width: 56,
          height: 64,
          margin: const EdgeInsets.only(right: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: i < _typed.length ? Night.warm : Night.cardEdge, width: 2)),
          child: Text(i < _typed.length ? _typed[i] : '', style: const TextStyle(fontSize: 30, color: Night.text)),
        );
    Widget key(String k) => Semantics(
          key: ValueKey('gate-key-$k'),
          container: true,
          button: true,
          label: k == '⌫' ? Strings.backspace : k,
          excludeSemantics: true,
          child: Material(
            color: Night.card,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: locked ? null : () => _key(k),
              child: Center(child: k == '⌫' ? const Icon(Icons.backspace_outlined, color: Night.soft) : Text(k, style: const TextStyle(fontSize: 26, color: Night.text))),
            ),
          ),
        );
    return Scaffold(
      backgroundColor: Night.deep,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Row(children: [
                const Expanded(child: Text(Strings.callParent, style: TextStyle(fontSize: 20, color: Night.text))),
                IconButton(tooltip: Strings.cancel, onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.close_rounded, color: Night.soft)),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Night.sky, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: Night.soft),
                    SizedBox(width: 8),
                    Text(Strings.parentGateTitle, style: TextStyle(fontSize: 15, color: Night.soft)),
                  ]),
                  const SizedBox(height: 10),
                  Text(locked ? Strings.gateWait(wait) : _challenge.question, style: const TextStyle(fontSize: 24, color: Night.text)),
                  const SizedBox(height: 16),
                  if (!locked) Row(children: [for (var i = 0; i < need; i++) box(i)]),
                  const SizedBox(height: 12),
                  Text(_wrong ? Strings.wrongAnswer : Strings.gateRules, style: TextStyle(fontSize: 14, color: _wrong ? const Color(0xFFF0A08A) : Night.soft)),
                ]),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9']) key(k),
                  const SizedBox.shrink(),
                  key('0'),
                  key('⌫'),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
