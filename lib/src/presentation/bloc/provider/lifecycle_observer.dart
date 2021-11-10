import 'package:flutter/material.dart';

abstract class LifecycleAware {
  void onResume();
  void onPause();
  void onDetach();
  void onInactive();
}

mixin LifecycleObserver on WidgetsBindingObserver {
  AppLifecycleState _lastAppState = AppLifecycleState.resumed;
  final Set<LifecycleAware> _listeners = {};

  void addListener(LifecycleAware listener) {
    _listeners.add(listener);
  }

  void removeListener(LifecycleAware listener) {
    _listeners.remove(listener);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _listeners
          .whereType<LifecycleAware>()
          .forEach((element) => element.onPause());
    } else if (state == AppLifecycleState.resumed &&
        _lastAppState == AppLifecycleState.paused) {
      _listeners
          .whereType<LifecycleAware>()
          .forEach((element) => element.onResume());
    } else if (state == AppLifecycleState.inactive) {
      _listeners
          .whereType<LifecycleAware>()
          .forEach((element) => element.onInactive());
    } else if (state == AppLifecycleState.detached) {
      _listeners
          .whereType<LifecycleAware>()
          .forEach((element) => element.onDetach());
    }
    _lastAppState = state;
  }
}
