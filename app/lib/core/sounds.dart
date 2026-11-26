import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'content.dart';

/// The long, quiet loops (design/sounds/make_sounds.py): the street at
/// dusk losing a layer as the lights go out, the soft wind after, and the
/// lullabies and the white noise.
enum Music {
  dusk('amb_dusk'),
  duskQuiet('amb_quiet'),
  wind('amb_wind'),
  musicBox1('musicbox_1'),
  musicBox2('musicbox_2'),
  musicBox3('musicbox_3'),
  humming1('humming_1'),
  humming2('humming_2'),
  rain('rain'),
  waves('waves'),
  fan('fan'),
  heartbeat('heartbeat');

  const Music(this.file);

  final String file;

  /// The loop for a lullaby: the music box has three tunes and the humming
  /// two, taken in turn night by night.
  static Music of(Lullaby l, int night) => switch (l) {
        Lullaby.musicBox => const [musicBox1, musicBox2, musicBox3][night % 3],
        Lullaby.humming => const [humming1, humming2][night % 2],
        Lullaby.rain => rain,
        Lullaby.waves => waves,
        Lullaby.fan => fan,
        Lullaby.heartbeat => heartbeat,
      };

  /// The street's sound with [dark] of its lights out (0 to 1).
  static Music street(double dark) => dark < 0.34 ? dusk : (dark < 0.67 ? duskQuiet : wind);
}

/// Short sounds are named by their file in assets/sounds/ (puff, yawn_cat,
/// sheep_hop…; design/sounds/README.md lists them).
abstract interface class Sounds {
  /// All sounds together (the parent's volume), 0 to 1.
  set volume(double v);
  set effects(bool on);

  void play(String sfx);

  /// [owner] (a screen) wants [music] at [level] (0 to 1); the one asked
  /// for last plays. Asking again with another level changes the volume.
  void hold(Object owner, Music? music, {double level = 1});

  void release(Object owner);
}

class MusicHolders {
  final _holders = <Object, (Music?, double)>{};

  void hold(Object owner, Music? music, double level) {
    _holders.remove(owner);
    _holders[owner] = (music, level);
  }

  void release(Object owner) => _holders.remove(owner);

  Music? get current => _holders.isEmpty ? null : _holders.values.last.$1;

  double get level => _holders.isEmpty ? 0 : _holders.values.last.$2;
}

class SilentSounds implements Sounds {
  const SilentSounds();

  @override
  set volume(double v) {}

  @override
  set effects(bool on) {}

  @override
  void play(String sfx) {}

  @override
  void hold(Object owner, Music? music, {double level = 1}) {}

  @override
  void release(Object owner) {}
}

/// Remembers the sounds played (tests).
class RecordingSounds implements Sounds {
  final played = <String>[];
  final _holders = MusicHolders();

  Music? get music => _holders.current;
  double get level => _holders.level;

  @override
  set volume(double v) {}

  @override
  set effects(bool on) {}

  @override
  void play(String sfx) => played.add(sfx);

  @override
  void hold(Object owner, Music? music, {double level = 1}) => _holders.hold(owner, music, level);

  @override
  void release(Object owner) => _holders.release(owner);
}

/// How every player plays: on the phone's media stream (the volume a parent
/// turns up for videos), not the ringer, so the lullaby is not silent in
/// vibrate or silent mode; asking for no audio focus, so sounds never stop
/// each other or the voice. On iOS a mixable ambient session.
final soundContext = AudioContext(
  android: const AudioContextAndroid(
    usageType: AndroidUsageType.media,
    contentType: AndroidContentType.music,
    audioFocus: AndroidAudioFocus.none,
  ),
  iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
);

/// Plays through audioplayers: a pool per sound, one looping player for the
/// loops; quiet while the app is in the background (0.1 has no background
/// playing). Everything is softer than in the sibling apps.
class SystemSounds implements Sounds {
  SystemSounds() {
    _lifecycle = AppLifecycleListener(onHide: () => _setAway(true), onShow: () => _setAway(false));
  }

  static const _sfxVolume = 0.55, _loopVolume = 0.6;

  late final AppLifecycleListener _lifecycle;
  final _pools = <String, Future<AudioPool>>{};
  final _holders = MusicHolders();
  Future<void>? _setUp;
  AudioPlayer? _loop;

  /// The loop wanted, and the loop really playing.
  Music? _playing, _sounding;

  /// Switches of the loop, one after the other: a stop asked for while a
  /// start is still loading waits for it, so a loop never starts after it
  /// was stopped (the app hidden, parent mode, the good night).
  Future<void> _switching = Future.value();
  var _volume = 0.7, _effects = true, _away = false;

  @override
  set volume(double v) {
    _volume = v;
    _setLevel();
  }

  @override
  set effects(bool on) => _effects = on;

  void _setAway(bool away) {
    _away = away;
    _update();
  }

  Future<void> _ready() => _setUp ??= AudioPlayer.global.setAudioContext(soundContext);

  @override
  void play(String sfx) {
    if (!_effects || _away || sfx.isEmpty) return;
    unawaited(_play(sfx));
  }

  Future<void> _play(String sfx) async {
    try {
      await _ready();
      final pool = await (_pools[sfx] ??= AudioPool.create(source: AssetSource('sounds/$sfx.wav'), maxPlayers: 3, audioContext: soundContext));
      await pool.start(volume: _sfxVolume * _volume);
    } catch (_) {
      _pools.remove(sfx);
    }
  }

  @override
  void hold(Object owner, Music? music, {double level = 1}) {
    _holders.hold(owner, music, level);
    _update();
  }

  @override
  void release(Object owner) {
    _holders.release(owner);
    _update();
  }

  double get _loopLevel => _loopVolume * _volume * _holders.level;

  void _setLevel() {
    final loop = _loop;
    if (loop != null && _sounding != null) unawaited(loop.setVolume(_loopLevel).catchError((_) {}));
  }

  void _update() {
    final wanted = _away ? null : _holders.current;
    if (wanted == _playing) {
      _setLevel();
      return;
    }
    _playing = wanted;
    _switching = _switching.then((_) => _apply());
  }

  /// Makes the loop play what is wanted now (a later wish queues another).
  Future<void> _apply() async {
    final music = _playing;
    if (music == _sounding) return;
    try {
      await _ready();
      var loop = _loop;
      if (loop == null) {
        loop = _loop = AudioPlayer();
        await loop.setAudioContext(soundContext);
        await loop.setReleaseMode(ReleaseMode.loop);
      }
      await loop.stop();
      _sounding = null;
      if (music == null) return;
      await loop.setVolume(_loopLevel);
      await loop.play(AssetSource('sounds/${music.file}.wav'));
      _sounding = music;
    } catch (_) {
      _sounding = null;
    }
  }

  void dispose() {
    _lifecycle.dispose();
    unawaited(_loop?.dispose());
  }
}
