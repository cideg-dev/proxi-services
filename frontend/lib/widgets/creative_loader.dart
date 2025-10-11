import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

enum LoaderType {
  dots,
  cube,
  pulse,
}

class CreativeLoader extends StatelessWidget {
  final Color color;
  final double size;
  final LoaderType type;

  const CreativeLoader({
    super.key,
    required this.color,
    this.size = 50.0,
    this.type = LoaderType.dots,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoaderType.dots:
        return SpinKitThreeBounce(
          color: color,
          size: size,
        );
      case LoaderType.cube:
        return SpinKitFadingCube(
          color: color,
          size: size,
        );
      case LoaderType.pulse:
        return SpinKitPulse(
          color: color,
          size: size,
        );
    }
  }
}
