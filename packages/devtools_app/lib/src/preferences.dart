// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'config_specific/logger/logger.dart';
import 'globals.dart';
import 'vm_service_wrapper.dart';

/// A controller for global application preferences.
class PreferencesController {
  Map<String, List<double>> _initialFractions;

  final ValueNotifier<bool> _darkModeTheme = ValueNotifier(true);
  final ValueNotifier<bool> _vmDeveloperMode = ValueNotifier(false);
  final ValueNotifier<bool> _denseMode = ValueNotifier(false);
  final _splitFractions = <String, ValueListenable<List<double>>>{};

  ValueListenable<bool> get darkModeTheme => _darkModeTheme;
  ValueListenable<bool> get vmDeveloperModeEnabled => _vmDeveloperMode;
  ValueListenable<bool> get denseModeEnabled => _denseMode;

  ValueNotifier<List<double>> lookupSplitFractions(String key) {
    return _splitFractions.putIfAbsent(
        key, () => ValueNotifier<List<double>>(_initialFractions[key] ?? []));
  }

  Future<void> init() async {
    if (storage != null) {
      // Get the current values and listen for and write back changes.
      String value = await storage.getValue('ui.darkMode');
      toggleDarkModeTheme(value == null || value == 'true');
      _darkModeTheme.addListener(() {
        storage.setValue('ui.darkMode', '${_darkModeTheme.value}');
      });

      value = await storage.getValue('ui.vmDeveloperMode');
      toggleVmDeveloperMode(value == 'true');
      _vmDeveloperMode.addListener(() {
        storage.setValue('ui.vmDeveloperMode', '${_vmDeveloperMode.value}');
      });

      value = await storage.getValue('ui.denseMode');
      toggleDenseMode(value == 'true');
      _denseMode.addListener(() {
        storage.setValue('ui.denseMode', '${_denseMode.value}');
      });

      _initialFractions = fractionsFromJson(
          jsonDecode(await storage.getValue('ui.splitFractions') ?? '{}'));
    } else {
      // This can happen when running tests.
      log('PreferencesController: storage not initialized');
    }
    setGlobal(PreferencesController, this);
  }

  /// Change the value for the dark mode setting.
  void toggleDarkModeTheme(bool useDarkMode) {
    _darkModeTheme.value = useDarkMode;
  }

  /// Change the value for the VM developer mode setting.
  void toggleVmDeveloperMode(bool enableVmDeveloperMode) {
    _vmDeveloperMode.value = enableVmDeveloperMode;
    VmServicePrivate.enablePrivateRpcs = enableVmDeveloperMode;
  }

  /// Change the value for the dense mode setting.
  void toggleDenseMode(bool enableDenseMode) {
    _denseMode.value = enableDenseMode;
  }

  /// Change the value for the split fractions setting.
  void saveSplitFractions(String key, List<double> splitFractions) {
    if ((key?.isEmpty ?? true) ||
        (splitFractions?.length ?? 0) < 2 ||
        jsonEncode(lookupSplitFractions(key).value) ==
            jsonEncode(splitFractions)) return;
    lookupSplitFractions(key).value = splitFractions;
    storage.setValue(
        'ui.splitFractions', jsonEncode(fractionsToJson(_splitFractions)));
  }

  Map<String, List<double>> fractionsFromJson(Map<String, dynamic> json) {
    return json
        .map((key, fractions) => MapEntry(key, fractions?.cast<double>()));
  }

  Map<String, List<double>> fractionsToJson(
      Map<String, ValueListenable<List<double>>> fractions) {
    return fractions.map((key, fractions) => MapEntry(key, fractions.value));
  }
}
