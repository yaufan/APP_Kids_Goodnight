import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goodnight_town/features/parent/parent_gate.dart';

import 'helpers.dart';

/// Privacy and the parent gate (docs/design.md: no network, nothing leaves
/// the phone, no permissions at all, parent mode only through the gate).
void main() {
  test('the app asks for no permissions and takes no links from other apps', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, isNot(contains('uses-permission')), reason: 'no internet, no wake lock, no location…');
    expect(manifest, contains('android:name="flutter_deeplinking_enabled" android:value="false"'));
    expect(File('ios/Runner/Info.plist').readAsStringSync(), contains('<key>FlutterDeepLinkingEnabled</key>\n\t<false/>'));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('source: system')));
    expect(pubspec, isNot(contains('wakelock')), reason: 'the screen is kept awake by the window flag, no permission');
  });

  test('the screen is kept awake by the window, not by a permission', () {
    final activity = File('android/app/src/main/kotlin/com/yaufan/goodnight_town/MainActivity.kt').readAsStringSync();
    expect(activity, contains('FLAG_KEEP_SCREEN_ON'));
    expect(activity, contains('screenBrightness'));
    expect(File('ios/Runner/AppDelegate.swift').readAsStringSync(), contains('isIdleTimerDisabled'));
    for (final f in Directory('android/app/src/main').listSync(recursive: true).whereType<File>()) {
      if (f.path.endsWith('.xml')) expect(f.readAsStringSync(), isNot(contains('WAKE_LOCK')), reason: f.path);
    }
  });

  testWidgets('parent mode and unknown pages cannot be opened without the gate', (tester) async {
    final app = await TestApp.start(tester);
    app.go('/parent');
    await app.settle();
    expect(app.location, '/', reason: 'no pass from the gate');
    ParentPass.grant();
    app.go('/parent');
    await app.settle();
    expect(app.location, '/parent', reason: 'right after the gate');
    app.go('/');
    await app.settle();
    app.go('/parent');
    await app.settle();
    expect(app.location, '/', reason: 'the pass is used up');
    app.go('/nothing/here');
    await app.settle();
    expect(app.location, '/');
    await app.end();
  });

  testWidgets('a wrong answer does not open parent mode', (tester) async {
    final app = await TestApp.start(tester);
    await app.tapKey('parent-corner', ms: 800);
    // 0 (or 00) is never right: the numbers added are 3 to 9, written as characters.
    await app.tapKey('gate-key-0', ms: 200);
    if (find.text('不對喔，換一題。').evaluate().isEmpty) await app.tapKey('gate-key-0', ms: 200);
    expect(find.text('不對喔，換一題。'), findsOneWidget);
    expect(ParentPass.take(), isFalse);
    await app.end();
  });
}
