import 'package:flutter/material.dart';

const kMonoFamily = 'JetBrains Mono';
const kMonoFallback = ['Cascadia Code', 'Fira Code', 'monospace'];

TextStyle mono(
  Color color, {
  double size = 13,
  FontWeight weight = FontWeight.w400,
  FontStyle style = FontStyle.normal,
  TextDecoration? decoration,
}) =>
    TextStyle(
      fontFamily: kMonoFamily,
      fontFamilyFallback: kMonoFallback,
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      decoration: decoration,
      decorationColor: color,
      color: color,
      height: 1.5,
    );
