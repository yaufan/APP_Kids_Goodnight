import 'dart:io';

import 'package:flutter/services.dart';

/// The phone's screen, through the app's own window only (no permission):
/// kept awake through the evening and the lullaby, turned right down while
/// it is black, and the app closing itself at the end (docs/design.md
/// 「搖籃曲與白噪音」).
abstract interface class ScreenControl {
  /// Keeps the screen from sleeping while the evening and the lullaby run.
  Future<void> keepOn(bool on);

  /// This window's brightness right down (Android) while the picture is black.
  Future<void> dim(bool on);

  /// The app closes itself (Android). iOS does not let an app close, so
  /// there the black 「晚安」 screen simply stays.
  Future<void> close();
}

class SystemScreen implements ScreenControl {
  static const _channel = MethodChannel('goodnight_town/screen');

  @override
  Future<void> keepOn(bool on) async {
    try {
      await _channel.invokeMethod<void>('keepOn', on);
    } catch (_) {}
  }

  @override
  Future<void> dim(bool on) async {
    try {
      if (Platform.isAndroid) await _channel.invokeMethod<void>('dim', on);
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await keepOn(false);
    await dim(false);
    if (Platform.isAndroid) await SystemNavigator.pop();
  }
}

/// The screen is kept awake while one of its owners (a screen on top) wants
/// it, and not a moment longer: covered by a parent screen, or the evening
/// over, the phone sleeps as it always does.
class Awake {
  Awake(this._screen);

  final ScreenControl _screen;
  final _owners = <Object>{};

  bool get on => _owners.isNotEmpty;

  void set(Object owner, bool on) {
    final before = this.on;
    if (on) {
      _owners.add(owner);
    } else {
      _owners.remove(owner);
    }
    if (this.on != before) _screen.keepOn(this.on);
  }
}

/// Remembers what was asked (tests).
class RecordingScreen implements ScreenControl {
  var awake = false;
  var dimmed = false;
  var closed = 0;

  @override
  Future<void> keepOn(bool on) async => awake = on;

  @override
  Future<void> dim(bool on) async => dimmed = on;

  @override
  Future<void> close() async {
    awake = false;
    dimmed = false;
    closed++;
  }
}
