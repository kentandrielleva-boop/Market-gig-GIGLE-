import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:marketplace_gig/core/performance/device_tier.dart';

Future<DeviceTier> detectDeviceTier() async {
  if (kIsWeb || !Platform.isAndroid) {
    return DeviceTier.high;
  }

  try {
    final info = await DeviceInfoPlugin().androidInfo;
    if (info.version.sdkInt < 26) {
      return DeviceTier.low;
    }
    final model = info.model.toLowerCase();
    const lowEndHints = ['go', 'a1', 'a2', 'redmi 6', 'redmi 7a', 'sm-a022'];
    if (lowEndHints.any(model.contains)) {
      return DeviceTier.low;
    }
    return DeviceTier.high;
  } catch (_) {
    return DeviceTier.low;
  }
}
