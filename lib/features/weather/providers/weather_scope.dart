import 'package:flutter/widgets.dart';

import 'weather_provider.dart';

class WeatherScope extends InheritedWidget {
  const WeatherScope({
    required this.provider,
    required super.child,
    super.key,
  });

  final WeatherProvider provider;

  static WeatherProvider watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WeatherScope>();
    assert(scope != null, 'WeatherScope is missing above this context.');
    return scope!.provider;
  }

  static WeatherProvider read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<WeatherScope>();
    assert(scope != null, 'WeatherScope is missing above this context.');
    return scope!.provider;
  }

  @override
  bool updateShouldNotify(WeatherScope oldWidget) => true;
}

