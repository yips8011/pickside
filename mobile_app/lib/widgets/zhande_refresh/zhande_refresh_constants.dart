import 'package:flutter/widgets.dart';

/// Trigger distance for pull-to-refresh (px)
const double kZhandeTriggerDistance = 105.0;

/// Maximum horizontal offset for 站/队 text animation (px)
const double kZhandeTextMaxOffset = 70.0;

/// Minimum height required to render header content (px)
const double kZhandeContentMinHeight = 90.0;

/// Font size for 站/队 text
const double kZhandeTextFontSize = 34.0;

/// Minimum text scale during pull
const double kZhandeTextScaleMin = 0.85;
const double kZhandeTextScaleMax = 1.0;

/// Animation durations
const Duration kZhandeBounceDuration = Duration(milliseconds: 250);
const Duration kZhandeBreathingDuration = Duration(milliseconds: 1200);
const Duration kZhandeGlowDuration = Duration(milliseconds: 400);
const Duration kZhandeCloseDuration = Duration(milliseconds: 220);
const Duration kZhandeSuccessDuration = Duration(seconds: 1);

/// Colors
const Color kZhandeGrayColor = Color(0xFF909090);
const Color kZhandeGreenColor = Color(0xFF5CE1A5);
const Color kZhandeSuccessTextColor = Color(0xFF64748B);

/// Random success messages
const List<String> kZhandeCompleteMessages = [
  '新的声音来了',
  '看看大家站哪边',
  '听听不同的声音',
  '总有人与你同路',
  '你的队友正在赶来',
  '你并不孤单',
];
