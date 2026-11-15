// Written by design/art/street.py: do not edit by hand.
import 'dart:ui';

import 'content.dart';

/// The street picture's size (assets/art/street/street.svg), in street units.
const streetSize = Size(700, 520);

/// The middle of the street that every screen shows whole (the lights are inside it).
const streetCore = Rect.fromLTWH(150, 120, 400, 400);

/// Where a light's pieces go on the street.
class LightPlace {
  const LightPlace({required this.art, required this.tap, this.animal, this.pane});

  /// `assets/art/street/glow_<light>.svg`.
  final Rect art;

  /// Where a finger turns it off.
  final Rect tap;

  /// Where its animal sits (null: no animal).
  final Rect? animal;

  /// A window pane with an iron cage (assets/art/street/grille.svg) over it and its animal.
  final Rect? pane;
}

const lightPlaces = <Light, LightPlace>{
  Light.cat: LightPlace(art: Rect.fromLTWH(144, 180, 88, 94), tap: Rect.fromLTWH(165, 201, 46, 52), animal: Rect.fromLTWH(170, 206, 36, 42), pane: Rect.fromLTWH(170, 206, 36, 42)),
  Light.rabbit: LightPlace(art: Rect.fromLTWH(320, 124, 88, 94), tap: Rect.fromLTWH(341, 145, 46, 52), animal: Rect.fromLTWH(346, 150, 36, 42), pane: Rect.fromLTWH(346, 150, 36, 42)),
  Light.bear: LightPlace(art: Rect.fromLTWH(262, 184, 88, 94), tap: Rect.fromLTWH(283, 205, 46, 52), animal: Rect.fromLTWH(288, 210, 36, 42), pane: Rect.fromLTWH(288, 210, 36, 42)),
  Light.duck: LightPlace(art: Rect.fromLTWH(188, 242, 88, 94), tap: Rect.fromLTWH(209, 263, 46, 52), animal: Rect.fromLTWH(214, 268, 36, 42), pane: Rect.fromLTWH(214, 268, 36, 42)),
  Light.pig: LightPlace(art: Rect.fromLTWH(262, 244, 88, 94), tap: Rect.fromLTWH(283, 265, 46, 52), animal: Rect.fromLTWH(288, 270, 36, 42), pane: Rect.fromLTWH(288, 270, 36, 42)),
  Light.owl: LightPlace(art: Rect.fromLTWH(444, 206, 88, 94), tap: Rect.fromLTWH(465, 227, 46, 52), animal: Rect.fromLTWH(470, 232, 36, 42), pane: Rect.fromLTWH(470, 232, 36, 42)),
  Light.dog: LightPlace(art: Rect.fromLTWH(264, 376, 106, 88), tap: Rect.fromLTWH(284, 396, 66, 48), animal: Rect.fromLTWH(300, 401, 34, 41)),
  Light.window: LightPlace(art: Rect.fromLTWH(320, 184, 88, 94), tap: Rect.fromLTWH(341, 205, 46, 52), pane: Rect.fromLTWH(346, 210, 36, 42)),
  Light.door: LightPlace(art: Rect.fromLTWH(336, 376, 68, 92), tap: Rect.fromLTWH(351, 390, 42, 58)),
  Light.lantern: LightPlace(art: Rect.fromLTWH(408, 382, 64, 70), tap: Rect.fromLTWH(418, 394, 44, 44)),
  Light.sign: LightPlace(art: Rect.fromLTWH(452, 356, 102, 52), tap: Rect.fromLTWH(466, 360, 74, 42)),
  Light.lamp: LightPlace(art: Rect.fromLTWH(192, 336, 74, 112), tap: Rect.fromLTWH(200, 336, 52, 46)),
};
