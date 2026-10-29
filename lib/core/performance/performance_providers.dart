import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';
import 'package:marketplace_gig/core/performance/device_tier_detector.dart';

final deviceTierProvider = FutureProvider<DeviceTier>((ref) async {
  return detectDeviceTier();
});

final animationBudgetProvider = StateProvider<AnimationBudget>(
  (ref) => AnimationBudget.full,
);
