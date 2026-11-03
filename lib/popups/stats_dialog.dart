import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../models/leveling.dart';
import '../models/task.dart';

/// Stats popup in the style of the Persona social-stats screen: a pentagon whose
/// vertices (one per category) reach farther from the center as more XP is earned there.
/// Colors follow the pitch deck: salmon background with orange rings, dark header tab.
class StatsDialog extends StatelessWidget {
  final Map<String, int> xp, count;
  final int streak, best;
  const StatsDialog({super.key, required this.xp, required this.count, this.streak = 0, this.best = 0});

  static const salmon = Color(0xFFFF806F); // deck background colour ("THE DIFFERENCE" slide)
  static const ring = lightOrange; // the deck's orange rings (same slide)
  // vertex order: top, right, bottom-right, bottom-left, left
  static const _colors = [coral, orange, coral, coral, orange];

  Widget _label(String c, Color color, double d) {
    final fg = color == coral ? cream : cocoa; // cream on coral, dark on orange
    final lv = levelFor(xp[c] ?? 0).level;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: cocoa, width: 2.5)),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(c, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            Text('LV $lv', style: pixel(14, fg, height: 1.2)),
            Text('${xp[c] ?? 0} XP', style: pixel(9, fg, height: 1.3)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const slant = 12.0;
    final screen = MediaQuery.of(context).size;
    final maxXp = xp.values.fold(0, (a, b) => a > b ? a : b);
    // vertices scale against your biggest category, with a floor of 100 XP so a new
    // hero starts with a small polygon that grows as tasks get done
    final scale = maxXp < 100 ? 100 : maxXp;
    final fractions = [for (final c in categories) ((xp[c] ?? 0) / scale).clamp(0.0, 1.0).toDouble()];
    final totalXp = xp.values.fold(0, (a, b) => a + b);
    final totalDone = count.values.fold(0, (a, b) => a + b);
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      // ~90% of the screen width; height follows the content
      insetPadding: EdgeInsets.symmetric(horizontal: screen.width * 0.05, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: Stack(children: [
            Positioned.fill(
              child: Transform.translate(offset: const Offset(8, 8), child: ClipPath(clipper: const Para(slant), child: const ColoredBox(color: cocoa))),
            ),
            ClipPath(
              clipper: const Para(slant),
              child: Container(
                color: salmon,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(
                        child: ClipPath(
                          clipper: const HeaderClip(),
                          child: Container(
                            color: cocoa,
                            padding: const EdgeInsets.fromLTRB(slant + 18, 14, 34, 14),
                            child: Text('STATS', style: pixel(26, cream, weight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: cocoa, size: 28), onPressed: () => Navigator.pop(context)),
                    ]),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(slant + 14, 12, slant + 14, 8),
                      child: LayoutBuilder(builder: (_, box) {
                        final w = box.maxWidth;
                        final h = w * 0.88;
                        final r = w * 0.32; // distance from center to label circle centers
                        final d = w * 0.27; // label circle diameter
                        final rg = r - d / 2 - 6; // polygon/guide max radius: stops 6px short of the circle border
                        final center = Offset(w / 2, w * 0.46);
                        Offset vertex(int i, double rad) {
                          final a = -math.pi / 2 + i * 2 * math.pi / 5;
                          return center + Offset(math.cos(a), math.sin(a)) * rad;
                        }

                        return Center(
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: Stack(clipBehavior: Clip.none, children: [
                              Positioned.fill(child: CustomPaint(painter: _RadarPainter(fractions, center, rg))),
                              for (var i = 0; i < categories.length; i++)
                                Positioned(
                                  left: vertex(i, r).dx - d / 2,
                                  top: vertex(i, r).dy - d / 2,
                                  child: _label(categories[i], _colors[i], d),
                                ),
                            ]),
                          ),
                        );
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(slant + 22, 4, slant + 22, 22),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('TOTAL  $totalXp XP  ·  $totalDone TASKS DONE', textAlign: TextAlign.center, style: pixel(12, cocoa, height: 1.3)),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.local_fire_department, color: cocoa, size: 20),
                          const SizedBox(width: 4),
                          Text('STREAK $streak  ·  BEST $best', style: pixel(12, cocoa, height: 1.3)),
                        ]),
                      ]),
                    ),
                        ]),
                      ),
                    ),
                  ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Pentagon radar chart: orange deck-style rings behind, guide rings + spokes, and a filled
/// polygon whose vertices sit farther from the center the higher each category's fraction is.
class _RadarPainter extends CustomPainter {
  final List<double> fractions;
  final Offset center;
  final double radius;
  const _RadarPainter(this.fractions, this.center, this.radius);

  Offset _pt(int i, double r) {
    final a = -math.pi / 2 + i * 2 * math.pi / 5;
    return center + Offset(math.cos(a), math.sin(a)) * r;
  }

  Path _poly(List<double> radii) {
    final p = Path()..moveTo(_pt(0, radii[0]).dx, _pt(0, radii[0]).dy);
    for (var i = 1; i < radii.length; i++) {
      p.lineTo(_pt(i, radii[i]).dx, _pt(i, radii[i]).dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // concentric orange rings, like the pitch deck backgrounds
    final rings = Paint()
      ..style = PaintingStyle.stroke
      ..color = StatsDialog.ring.withOpacity(0.55);
    canvas.drawCircle(center, radius * 1.75, rings..strokeWidth = radius * 0.22);
    canvas.drawCircle(center, radius * 2.45, rings..strokeWidth = radius * 0.3);

    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = cocoa.withOpacity(0.28);
    // guide rings (33% / 66%) and the outer pentagon
    for (final k in [1 / 3, 2 / 3]) {
      canvas.drawPath(_poly(List.filled(5, radius * k)), guide);
    }
    canvas.drawPath(_poly(List.filled(5, radius)), guide..strokeWidth = 3..color = cocoa.withOpacity(0.6));
    // spokes
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(center, _pt(i, radius), guide..strokeWidth = 1.5..color = cocoa.withOpacity(0.28));
    }
    // data polygon: never collapses fully, so an empty hero still shows a small shape
    final radii = [for (final f in fractions) radius * (0.12 + 0.88 * f)];
    final poly = _poly(radii);
    canvas.drawPath(poly, Paint()..color = cream.withOpacity(0.7));
    canvas.drawPath(
        poly,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.miter
          ..color = cocoa);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(_pt(i, radii[i]), 3.5, Paint()..color = coral);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter o) => o.fractions != fractions || o.center != center || o.radius != radius;
}
