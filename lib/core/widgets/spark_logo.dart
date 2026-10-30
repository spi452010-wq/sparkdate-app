import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Gradient circle with the heart + lightning mark (assets exported from Figma).
class SparkLogoMark extends StatelessWidget {
  const SparkLogoMark({super.key, this.size = 112});
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = size * .5;
    Widget part(String file, double l, double t, double r, double b) => Positioned(
          left: icon * l,
          top: icon * t,
          right: icon * r,
          bottom: icon * b,
          child: SvgPicture.asset('assets/icons/$file', fit: BoxFit.fill),
        );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 9 / 112),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x38FF5E7E), blurRadius: 32, offset: Offset(0, 12), spreadRadius: -4),
        ],
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.logoGradient),
        child: Center(
          child: SizedBox.square(
            dimension: icon,
            child: Stack(children: [
              part('splash_e11ed.svg', .15, .10, .0416, .12),
              part('splash_31e27.svg', .17, .12, .38, .145),
              part('splash_dfb20.svg', .42 - .0179, .22, .34 - .0179, .30 - .0357),
            ]),
          ),
        ),
      ),
    );
  }
}

class SparkWordmark extends StatelessWidget {
  const SparkWordmark({super.key, this.fontSize = 32});
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -fontSize * .025,
      color: AppColors.textTitle,
    );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('Spark', style: style),
      ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryMid],
        ).createShader(r),
        child: Text('Date', style: style.copyWith(color: Colors.white)),
      ),
    ]);
  }
}
