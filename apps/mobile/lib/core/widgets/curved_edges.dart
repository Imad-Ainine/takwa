import 'package:flutter/material.dart';

class CustomCurvedEdges extends CustomClipper<Path> {
  const CustomCurvedEdges();

  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);

    final firstCurve = Offset(0, size.height - 20);
    final lastCurve = Offset(30, size.height - 20);
    path.quadraticBezierTo(
      firstCurve.dx,
      firstCurve.dy,
      lastCurve.dx,
      lastCurve.dy,
    );

    final secondFirstCurve = Offset(0, size.height - 20);
    final secondLastCurve = Offset(size.width - 30, size.height - 20);
    path.lineTo(secondLastCurve.dx, secondLastCurve.dy);

    final thirdFirstCurve = Offset(size.width, size.height - 20);
    final thirdLastCurve = Offset(size.width, size.height);
    path.quadraticBezierTo(
      thirdFirstCurve.dx,
      thirdFirstCurve.dy,
      thirdLastCurve.dx,
      thirdLastCurve.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  // getClip() is a pure function of `size` alone — this clipper has no
  // fields, so no two instances can ever produce a different path for the
  // same size. `false` is correct, not just faster: a size change is
  // already handled separately by the render object regardless of what
  // this returns, and this used to hardcode `true`, forcing the non-
  // rectangular clip path to be recomputed on every rebuild of whatever
  // wraps it (TCurvedEdgeWidget), even a same-size one.
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class TCurvedEdgeWidget extends StatelessWidget {
  const TCurvedEdgeWidget({super.key, this.child, this.isCurved = true});
  final Widget? child;
  final bool isCurved;

  @override
  Widget build(BuildContext context) {
    if (!isCurved) return child ?? const SizedBox();
    return ClipPath(clipper: const CustomCurvedEdges(), child: child);
  }
}

class TCirculerContainer extends StatelessWidget {
  const TCirculerContainer({
    super.key,
    this.width,
    this.height,
    this.radius = 400,
    this.padding = 0,
    this.margin,
    this.child,
    this.backgroundColor = Colors.white,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final double radius;
  final double padding;
  final EdgeInsets? margin;
  final Widget? child;
  final Color backgroundColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(radius),
        color: backgroundColor,
      ),
      child: child,
    );
  }
}
