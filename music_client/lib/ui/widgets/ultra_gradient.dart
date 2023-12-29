import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:music_client/ui/theme.dart';

const numPoints = 4;

class AnimatedUltraGradient extends StatefulWidget {
  final Duration duration;
  final Duration maxStoppedDuration;
  final double opacity;
  final double pointSize;
  final Widget? child;

  const AnimatedUltraGradient({
    super.key,
    this.duration = const Duration(seconds: 20),
    this.maxStoppedDuration = const Duration(milliseconds: 2000),
    this.opacity = 0.75,
    this.pointSize = 1000.0,
    this.child,
  });

  @override
  State<AnimatedUltraGradient> createState() => _AnimatedUltraGradientState();
}

class _AnimatedUltraGradientState extends State<AnimatedUltraGradient> with TickerProviderStateMixin {
  FragmentShader? shader;
  late final AnimationController animationController;

  List<Color>? pointColors;
  late final List<double> pointSizes;

  List<(double x, double y)>? pointPositionsA;
  List<(double x, double y)>? pointPositionsB;

  late double maxHeight;
  late double maxWidth;

  @override
  void initState() {
    FragmentProgram.fromAsset('shaders/ultragradient.frag').then((value) {
      if (!mounted) return;
      setState(() => shader = value.fragmentShader());
    });
    animationController = AnimationController(vsync: this);

    pointSizes = List.generate(4, (index) => widget.pointSize);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      animate();
    });

    super.initState();
  }

  void animate() async {
    while (mounted) {
      await animationController.animateTo(1.0, duration: widget.duration, curve: Curves.easeInOut);
      pointPositionsA = List.from(pointPositionsB!);
      pointPositionsB = getNextPointPositions();
      animationController.reset();
      await Future.delayed(Duration(milliseconds: _random.nextInt(widget.maxStoppedDuration.inMilliseconds)));
    }
  }

  List<(double x, double y)> getNextPointPositions() => poissonDiskSample(
        count: numPoints,
        radius: maxHeight / numPoints,
        sizeX: maxWidth,
        sizeY: maxHeight,
      );

  @override
  void dispose() {
    shader?.dispose();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return shader != null
        ? LayoutBuilder(
            builder: (context, constraints) {
              maxHeight = constraints.maxHeight;
              maxWidth = constraints.maxWidth;
              return SizedBox.expand(
                child: AnimatedBuilder(
                    animation: animationController,
                    builder: (context, child) {
                      if (pointPositionsA == null || pointPositionsB == null) {
                        pointPositionsA = getNextPointPositions();
                        pointPositionsB = getNextPointPositions();
                      }

                      pointColors ??= [
                        darkTheme.colorScheme.inversePrimary,
                        darkTheme.colorScheme.errorContainer,
                        darkTheme.colorScheme.tertiaryContainer,
                        darkTheme.colorScheme.surfaceVariant,
                      ]..shuffle();

                      final pointPositions = lerpPositions(pointPositionsA!, pointPositionsB!, animationController.value);

                      return CustomPaint(
                        painter: UltraGradientPainter(
                          shader: shader!,
                          numPoints: pointPositions.length,
                          outputIntensity: widget.opacity,
                          pointPositions: pointPositions,
                          pointColors: pointColors!,
                          pointSizes: pointSizes,
                        ),
                        child: widget.child,
                      );
                    }),
              );
            },
          )
        : const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
  }
}

final listEquals = const ListEquality().equals;

class UltraGradientPainter extends CustomPainter {
  final FragmentShader shader;

  final int numPoints;
  final double outputIntensity;
  final List<(double x, double y)> pointPositions;
  final List<double> pointSizes;
  final List<Color> pointColors;

  UltraGradientPainter({
    required this.shader,
    required this.numPoints,
    required this.outputIntensity,
    required this.pointPositions,
    required this.pointSizes,
    required this.pointColors,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, outputIntensity);

    var i = 1;
    for (var k = 0; k < numPoints; k++) {
      shader.setFloat(i, pointPositions[k].$1);
      shader.setFloat(i + 1, pointPositions[k].$2);
      i += 2;
    }
    for (var k = 0; k < numPoints; k++) {
      shader.setFloat(i, pointSizes[k]);
      i++;
    }
    for (var k = 0; k < numPoints; k++) {
      shader.setFloat(i, pointColors[k].red.toDouble() / 255.0);
      shader.setFloat(i + 1, pointColors[k].green.toDouble() / 255.0);
      shader.setFloat(i + 2, pointColors[k].blue.toDouble() / 255.0);
      i += 3;
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(UltraGradientPainter oldDelegate) => true; // shader != oldDelegate.shader || !listEquals(pointPositions, oldDelegate.pointPositions) || !listEquals(pointSizes, oldDelegate.pointSizes) || !listEquals(pointColors, oldDelegate.pointColors);
}

final _random = Random();

/// Simple Poisson Disk Sampling. Generates random points until count valid points are found. Fails after 100 unsuccessful samples.
List<(double x, double y)> poissonDiskSample({required int count, required double radius, required double sizeX, required double sizeY}) {
  final points = [(_random.nextDouble() * sizeX, _random.nextDouble() * sizeY)];

  var i = 1;
  for (var k = 0; k < 100; k++) {
    final sample = (_random.nextDouble() * sizeX, _random.nextDouble() * sizeY);

    var valid = true;
    for (final point in points) {
      final difference = (sample.$1 - point.$1, sample.$2 - point.$2);
      final distance = sqrt(difference.$1 * difference.$1 + difference.$2 * difference.$2);

      if (distance < radius) {
        valid = false;
        break;
      }
    }
    if (valid) {
      points.add(sample);
      i++;
      if (i >= count) break;
    }
  }

  // If no more points can be generated, force random sample
  if (points.length < count) points.addAll(List.generate(count - points.length, (index) => (_random.nextDouble() * sizeX, _random.nextDouble() * sizeY)));

  return points;
}

List<(double x, double y)> lerpPositions(List<(double x, double y)> a, List<(double x, double y)> b, double c) {
  return a.mapIndexed((index, element) => (lerpDouble(element.$1, b[index].$1, c)!, lerpDouble(element.$2, b[index].$2, c)!)).toList();
}