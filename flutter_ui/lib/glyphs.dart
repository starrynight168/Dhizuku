import 'dart:math' as math;

import 'package:prism_ui/icons/glyph.dart'
    show
        Glyph,
        GlyphArc,
        GlyphBox,
        GlyphCircle,
        GlyphPath,
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

  static const adminShield = Glyph([
    GlyphPath(
      'M12 3L19.5 6V12C19.5 16.5 16.2 19.6 12 21C7.8 19.6 4.5 16.5 4.5 12V6Z M12 10.5A2 2 0 1 0 12 6.5A2 2 0 1 0 12 10.5 M8.8 15.8C9.4 14.2 10.6 13.5 12 13.5C13.4 13.5 14.6 14.2 15.2 15.8',
      role: GlyphRole.line,
    ),
  ]);

  static const heart = Glyph([
    GlyphPath(
      'M12 20.2C12 20.2 4 15.2 4 9.2A4.3 4.3 0 0 1 12 6.8A4.3 4.3 0 0 1 20 9.2C20 15.2 12 20.2 12 20.2Z',
      role: GlyphRole.line,
    ),
  ]);

  static const power = Glyph([
    GlyphPath(
      'M12 3.5V11 M7.2 6.2A7.5 7.5 0 1 0 16.8 6.2',
      role: GlyphRole.line,
    ),
  ]);

  static const edit = Glyph([
    GlyphPath(
      'M4 20H8L19 9L15 5L4 16Z M13.5 6.5L17.5 10.5',
      role: GlyphRole.line,
    ),
  ]);

  static const delete = Glyph([
    GlyphPath(
      'M4 7H20 M9 4H15 M7 7L8 20H16L17 7 M10 11V16 M14 11V16',
      role: GlyphRole.line,
    ),
  ]);

  static const play = Glyph([
    GlyphPath('M7 5L19 12L7 19Z', role: GlyphRole.line),
  ]);

  static const pause = Glyph([
    GlyphPath('M7.5 5.5V18.5 M16.5 5.5V18.5', role: GlyphRole.line),
  ]);

  static const add = Glyph([
    GlyphPath('M12 5V19 M5 12H19', role: GlyphRole.line),
  ]);

  static const bookmark = Glyph([
    GlyphPath('M6 3.5H18V20.5L12 16.5L6 20.5Z', role: GlyphRole.line),
  ]);

  static const android = Glyph([
    GlyphPath(
      'M6 12A6 6 0 0 1 18 12V18.5H6Z M8.5 7.2L6.8 4.4 M15.5 7.2L17.2 4.4 M9.5 11.2H9.7 M14.5 11.2H14.7',
      role: GlyphRole.line,
    ),
  ]);

  static const person = Glyph([
    GlyphPath(
      'M12 11.5A4 4 0 1 0 12 3.5A4 4 0 1 0 12 11.5 M4.5 20.5C4.5 16.8 7.8 15 12 15C16.2 15 19.5 16.8 19.5 20.5',
      role: GlyphRole.line,
    ),
  ]);

  static const accountCircle = Glyph([
    GlyphPath(
      'M12 3A9 9 0 1 0 12 21A9 9 0 1 0 12 3 M12 11.5A2.8 2.8 0 1 0 12 5.9A2.8 2.8 0 1 0 12 11.5 M6.8 18.8C7.8 16.4 9.7 15.2 12 15.2C14.3 15.2 16.2 16.4 17.2 18.8',
      role: GlyphRole.line,
    ),
  ]);

  static const palette = Glyph([
    GlyphPath(
      'M12 3A9 9 0 1 0 12 21C13.6 21 14.5 19.9 14.5 18.7C14.5 18 14.2 17.4 13.8 17C13.4 16.6 13.2 16 13.5 15.4C13.9 14.7 14.6 14.4 15.5 14.4H17.4A3.6 3.6 0 0 0 21 10.8C21 6.4 17 3 12 3Z M8 10H8.2 M10.5 7H10.7 M14.5 7.5H14.7 M16.8 10.5H17',
      role: GlyphRole.line,
    ),
  ]);

  static const book = Glyph([
    GlyphPath(
      'M4 5H11A2 2 0 0 1 12 7V19A2 2 0 0 0 10 18H4Z M20 5H13A2 2 0 0 0 12 7V19A2 2 0 0 1 14 18H20Z',
      role: GlyphRole.line,
    ),
  ]);

  static const battery = Glyph([
    GlyphPath(
      'M7 6H17V20.5H7Z M10 3.5H14V6H10Z M12.5 9.5L10 13.5H12.5L11.5 17L14 13H11.5Z',
      role: GlyphRole.line,
    ),
  ]);

  static const openInNew = Glyph([
    GlyphPath(
      'M14 4H20V10 M20 4L11 13 M18 14V20H4V6H10',
      role: GlyphRole.line,
    ),
  ]);

  static const description = Glyph([
    GlyphPath(
      'M6 3H14.5L18.5 7V21H6Z M14 3V7.5H18.5 M9 11.5H15.5 M9 15H15.5 M9 18.2H13',
      role: GlyphRole.line,
    ),
  ]);

  static const privacy = Glyph([
    GlyphPath(
      'M12 3L19.5 6V12C19.5 16.5 16.2 19.6 12 21C7.8 19.6 4.5 16.5 4.5 12V6Z M12 8.5V12.5 M12 15.5V16',
      role: GlyphRole.line,
    ),
  ]);

  static const sparkle = Glyph([
    GlyphPath(
      'M12 3L14 9L20 11L14 13L12 19L10 13L4 11L10 9Z',
      role: GlyphRole.line,
    ),
  ]);

  static const extension = Glyph([
    GlyphPath(
      'M4 5H10V7.5A1.5 1.5 0 1 0 14 7.5V5H20V10H17.5A1.5 1.5 0 1 0 17.5 14H20V20H14V17.5A1.5 1.5 0 1 0 10 17.5V20H4V14H6.5A1.5 1.5 0 1 0 6.5 10H4Z',
      role: GlyphRole.line,
    ),
  ]);

  static const checkCircle = Glyph([
    GlyphPath(
      'M12 3A9 9 0 1 0 12 21A9 9 0 1 0 12 3 M8.5 12.5L11 15L15.5 9.5',
      role: GlyphRole.line,
    ),
  ]);

  static const warning = Glyph([
    GlyphPath(
      'M12 3.5L21 19.5H3Z M12 9.5V13.5 M12 16.2V16.8',
      role: GlyphRole.line,
    ),
  ]);

  static const phoneAndroid = Glyph([
    GlyphPath(
      'M7 3H17V21H7Z M10.5 18H13.5 M7 6H17 M7 16H17',
      role: GlyphRole.line,
    ),
  ]);

  static const workspaces = Glyph([
    GlyphCircle(12, 6.5, 3, role: GlyphRole.line),
    GlyphCircle(6.5, 16.5, 3, role: GlyphRole.line),
    GlyphCircle(17.5, 16.5, 3, role: GlyphRole.line),
  ]);

  static const shield = Glyph([
    GlyphPath(
      'M12 3L20 6V12C20 16.5 16.5 19.5 12 21C7.5 19.5 4 16.5 4 12V6Z',
      role: GlyphRole.line,
    ),
  ]);

  static const terminal = Glyph([
    GlyphPath(
      'M3.5 5H20.5V19H3.5Z M7.5 9.5L10.5 12L7.5 14.5 M12.5 14.5H16.5',
      role: GlyphRole.line,
    ),
  ]);

  static const cloudOff = Glyph([
    GlyphPath(
      'M7 18H17 M4 4L20 20 M18 10A4 4 0 0 1 20 16',
      role: GlyphRole.line,
    ),
  ]);

  static const refresh = Glyph([
    GlyphPath(
      'M20 12A8 8 0 1 1 17.6 6.3 M20 4V9H15',
      role: GlyphRole.line,
    ),
  ]);
}
