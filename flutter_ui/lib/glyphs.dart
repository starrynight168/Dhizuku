import 'dart:math' as math;

import 'package:prism_ui/icons/glyph.dart'
    show
        Glyph,
        GlyphArc,
        GlyphBox,
        GlyphCircle,
        GlyphPolyline,
        GlyphRole,
        GlyphVertex;

abstract final class DhizukuGlyphs {
  static const dashboard = Glyph([
    GlyphBox(3.5, 3.5, 10.5, 11.5, 2),
    GlyphBox(13.5, 3.5, 20.5, 9.5, 2),
    GlyphBox(3.5, 14.5, 10.5, 20.5, 2),
    GlyphBox(13.5, 12.5, 20.5, 20.5, 2),
  ]);

  static const apps = Glyph([
    GlyphBox(3.5, 3.3, 6.9, 6.7, 1),
    GlyphBox(3.5, 10.3, 6.9, 13.7, 1),
    GlyphBox(3.5, 17.3, 6.9, 20.7, 1),
    GlyphPolyline([
      GlyphVertex(10.5, 5),
      GlyphVertex(20.5, 5),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(10.5, 12),
      GlyphVertex(20.5, 12),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(10.5, 19),
      GlyphVertex(20.5, 19),
    ], role: GlyphRole.line),
  ]);

  static const users = Glyph([
    GlyphCircle(12, 12, 8.8),
    GlyphCircle(12, 9.4, 2.8, role: GlyphRole.detail),
    GlyphArc(
      12,
      22.6,
      7,
      math.pi * -0.8087,
      math.pi * 0.6173,
      role: GlyphRole.detail,
    ),
  ]);

  static const verified = Glyph([
    GlyphPolyline([
      GlyphVertex(12, 2.9, 1.5),
      GlyphVertex(19.6, 5.5, 2),
      GlyphVertex(19.6, 12.5, 5),
      GlyphVertex(12, 21.1, 2.5),
      GlyphVertex(4.4, 12.5, 5),
      GlyphVertex(4.4, 5.5, 2),
    ], closed: true),
    GlyphPolyline([
      GlyphVertex(8.7, 11.8),
      GlyphVertex(11, 14.1),
      GlyphVertex(15.3, 9.6),
    ], role: GlyphRole.detail),
  ]);

  static const swap = Glyph([
    GlyphPolyline([
      GlyphVertex(3.5, 8),
      GlyphVertex(20.5, 8),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(17.5, 5),
      GlyphVertex(20.5, 8, 0.4),
      GlyphVertex(17.5, 11),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(20.5, 16),
      GlyphVertex(3.5, 16),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(6.5, 13),
      GlyphVertex(3.5, 16, 0.4),
      GlyphVertex(6.5, 19),
    ], role: GlyphRole.line),
  ]);

  static const logs = Glyph([
    GlyphBox(3, 4.5, 21, 19.5, 3.5),
    GlyphPolyline([
      GlyphVertex(7.3, 9.3),
      GlyphVertex(9.9, 11.9, 0.4),
      GlyphVertex(7.3, 14.5),
    ], role: GlyphRole.detail),
    GlyphPolyline([
      GlyphVertex(12.2, 14.5),
      GlyphVertex(16.2, 14.5),
    ], role: GlyphRole.detail),
  ]);

  static const settings = Glyph([
    GlyphPolyline([
      GlyphVertex(9.87, 5.44, 0.6),
      GlyphVertex(10.09, 3, 0.9),
      GlyphVertex(13.91, 3, 0.9),
      GlyphVertex(14.13, 5.44, 0.6),
      GlyphVertex(16.62, 6.87, 0.6),
      GlyphVertex(18.84, 5.84, 0.9),
      GlyphVertex(20.75, 9.16, 0.9),
      GlyphVertex(18.75, 10.57, 0.6),
      GlyphVertex(18.75, 13.43, 0.6),
      GlyphVertex(20.75, 14.84, 0.9),
      GlyphVertex(18.84, 18.16, 0.9),
      GlyphVertex(16.62, 17.13, 0.6),
      GlyphVertex(14.13, 18.56, 0.6),
      GlyphVertex(13.91, 21, 0.9),
      GlyphVertex(10.09, 21, 0.9),
      GlyphVertex(9.87, 18.56, 0.6),
      GlyphVertex(7.38, 17.13, 0.6),
      GlyphVertex(5.16, 18.16, 0.9),
      GlyphVertex(3.25, 14.84, 0.9),
      GlyphVertex(5.25, 13.43, 0.6),
      GlyphVertex(5.25, 10.57, 0.6),
      GlyphVertex(3.25, 9.16, 0.9),
      GlyphVertex(5.16, 5.84, 0.9),
      GlyphVertex(7.38, 6.87, 0.6),
    ], closed: true),
    GlyphCircle(12, 12, 3, role: GlyphRole.detail),
  ]);
}
