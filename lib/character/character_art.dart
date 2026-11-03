import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/palette.dart';

// Character art: assets/characters/<group>_<1-3>.png  (group = male | female | neutral)
const characterExt = 'png';

const characterGroups = {'Male': 'male', 'Female': 'female', 'Ambiguous': 'neutral'};
const defaultCharacter = 'neutral_1';

String characterPath(String id) => 'assets/characters/$id.$characterExt';

/// Character silhouette, recolored to [tint] (keeps the image's transparency, flattens its
/// colors). Falls back to an icon if the image file is missing.
Widget characterImage(String id, {Color tint = cocoa, BoxFit fit = BoxFit.contain, Alignment alignment = Alignment.bottomCenter}) => Image.asset(
      characterPath(id),
      fit: fit,
      alignment: alignment,
      color: tint,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (_, __, ___) => Center(child: Icon(Icons.person, size: 64, color: tint)),
    );

/// Decoded silhouette + the bounding box of its visible (non-transparent) pixels.
class _ArtData {
  final ui.Image image;
  final Rect bounds;
  const _ArtData(this.image, this.bounds);
}

final Map<String, Future<_ArtData?>> _artCache = {};

/// Loads a character image once and finds its visible bounds, so transparent padding in the
/// PNG does not stop the figure from reaching the edges of the profile band.
Future<_ArtData?> _loadArt(String id) => _artCache.putIfAbsent(id, () async {
      try {
        final data = await rootBundle.load(characterPath(id));
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final image = (await codec.getNextFrame()).image;
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        final w = image.width, h = image.height;
        var minX = w, minY = h, maxX = -1, maxY = -1;
        for (var y = 0; y < h; y += 2) {
          for (var x = 0; x < w; x += 2) {
            if (bytes.getUint8((y * w + x) * 4 + 3) > 20) {
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
            }
          }
        }
        final bounds = maxX < 0 ? Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()) : Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX + 2.0, maxY + 2.0);
        return _ArtData(image, bounds);
      } catch (_) {
        return null;
      }
    });

/// Pitch-deck style silhouette: a [main] colored figure with a [shadow] colored copy shifted
/// sideways behind it. The figure is scaled so its visible height (hair to neck) fills the
/// available height exactly, like the level-up screen portrait.
class CharacterArt extends StatelessWidget {
  final String id;
  final Color main, shadow;
  final double shadowDx;
  final bool alignRight; // true: sit against the right edge and spill leftwards
  const CharacterArt(this.id, {super.key, required this.main, required this.shadow, this.shadowDx = 8, this.alignRight = false});

  @override
  Widget build(BuildContext context) => FutureBuilder<_ArtData?>(
        future: _loadArt(id),
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
          final art = snap.data;
          if (art == null) return Center(child: Icon(Icons.person, size: 64, color: main)); // missing file
          return CustomPaint(size: Size.infinite, painter: _ArtPainter(art, main, shadow, shadowDx, alignRight));
        },
      );
}

class _ArtPainter extends CustomPainter {
  final _ArtData art;
  final Color main, shadow;
  final double dx;
  final bool alignRight;
  const _ArtPainter(this.art, this.main, this.shadow, this.dx, this.alignRight);

  @override
  void paint(Canvas canvas, Size size) {
    final b = art.bounds;
    final scale = size.height / b.height; // visible height -> full band height
    final dw = b.width * scale;
    final left = alignRight ? size.width - dw - dx - 10 : (size.width - dw) / 2;
    final dst = Rect.fromLTWH(left, 0, dw, size.height);
    final p = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(art.image, b, dst.shift(Offset(dx, 0)), p..colorFilter = ColorFilter.mode(shadow, BlendMode.srcIn));
    canvas.drawImageRect(art.image, b, dst, p..colorFilter = ColorFilter.mode(main, BlendMode.srcIn));
  }

  @override
  bool shouldRepaint(covariant _ArtPainter o) => o.art != art || o.main != main || o.shadow != shadow || o.dx != dx || o.alignRight != alignRight;
}
