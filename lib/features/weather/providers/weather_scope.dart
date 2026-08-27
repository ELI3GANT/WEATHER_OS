import 'package:flutter/widgets.dart';

import 'weather_provider.dart';

class WeatherScope extends InheritedNotifier<WeatherProvider> {
  const WeatherScope({
    required WeatherProvider provider,
    required super.child,
    super.key,
  }) : super(notifier: provider);

  static WeatherProvider watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WeatherScope>();
    assert(scope != null, 'WeatherScope is missing above this context.');
    return scope!.notifier!;
  }

  static WeatherProvider read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<WeatherScope>();
    assert(scope != null, 'WeatherScope is missing above this context.');
    return scope!.notifier!;
  }
}
