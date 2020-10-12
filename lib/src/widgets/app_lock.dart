import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget which handles app lifecycle events for showing and hiding a lock screen.
/// This should wrap around a `MyApp` widget (or equivalent).
///
/// [lockScreen] is a [Widget] which should be a screen for handling login logic and
/// calling `AppLock.of(context).didUnlock();` upon a successful login.
///
/// [builder] is a [Function] taking an [Object] as its argument and should return a
/// [Widget]. The [Object] argument is provided by the [lockScreen] calling
/// `AppLock.of(context).didUnlock();` with an argument. [Object] can then be injected
/// in to your `MyApp` widget (or equivalent).
///
/// [enabled] determines wether or not the [lockScreen] should be shown on app launch
/// and subsequent app pauses. This can be changed later on using `AppLock.of(context).enable();`,
/// `AppLock.of(context).disable();` or the convenience method `AppLock.of(context).setEnabled(enabled);`
/// using a bool argument.
class AppLock extends StatefulWidget {
  final WidgetBuilder builder;
  final Widget lockScreen;
  final bool enabled;

  const AppLock({
    Key key,
    @required this.builder,
    @required this.lockScreen,
    this.enabled = true,
  }) : super(key: key);

  static _AppLockState of(BuildContext context) => context
      .findAncestorWidgetOfExactType<_ApplockInheritedWidget>()
      .appLockState;

  @override
  _AppLockState createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> with WidgetsBindingObserver {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  bool _didUnlockForAppLaunch;
  bool _enabled;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    this._didUnlockForAppLaunch = !this.widget.enabled;
    this._enabled = this.widget.enabled;
    print('from plugin $_enabled');

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ApplockInheritedWidget(
      appLockState: this,
      child: MaterialApp(
        home: this.widget.enabled
            ? this._lockScreen
            : this.widget.builder(context),
        navigatorKey: _navigatorKey,
        routes: {
          '/lock-screen': (context) => this._lockScreen,
          '/unlocked': (context) => this.widget.builder(context)
          // this.widget.builder(Mod'alRoute.of(context).settings.arguments)
        },
      ),
    );
  }

  Widget get _lockScreen {
    return WillPopScope(
      child: this.widget.lockScreen,
      onWillPop: () => SystemNavigator.pop(),
    );
  }

  /// Causes `AppLock` to either pop the [lockScreen] if the app is already running
  /// or instantiates widget returned from the [builder] method if the app is cold
  /// launched.
  ///
  /// [args] is an optional argument which will get passed to the [builder] method
  /// when built. Use this when you want to inject objects created from the
  /// [lockScreen] in to the rest of your app so you can better guarantee that some
  /// objects, services or databases are already instantiated before using them.
  void didUnlock() {
    if (this._didUnlockForAppLaunch) {
      this._didUnlockOnAppPaused();
    } else {
      this._didUnlockOnAppLaunch();
    }
  }

  /// Makes sure that [AppLock] shows the [lockScreen] on subsequent app pauses if
  /// [enabled] is true of makes sure it isn't shown on subsequent app pauses if
  /// [enabled] is false.
  ///
  /// This is a convenience method for calling the [enable] or [disable] method based
  /// on [enabled].
  void setEnabled(bool enabled) {
    if (enabled) {
      this.enable();
    } else {
      this.disable();
    }
  }

  /// Makes sure that [AppLock] shows the [lockScreen] on subsequent app pauses.
  void enable() {
    // setState(() {
    this._enabled = true;
    // });
  }

  /// Makes sure that [AppLock] doesn't show the [lockScreen] on subsequent app pauses.
  void disable() {
    // setState(() {
    this._enabled = false;
    // });
  }

  /// Manually show the [lockScreen].
  Future<void> showLockScreen() {
    return _navigatorKey.currentState.pushNamed('/lock-screen');
  }

  void _didUnlockOnAppLaunch() {
    this._didUnlockForAppLaunch = true;
    _navigatorKey.currentState.pushReplacementNamed('/unlocked');
  }

  void _didUnlockOnAppPaused() {
    _navigatorKey.currentState.pop();
  }
}

class _ApplockInheritedWidget extends InheritedWidget {
  _ApplockInheritedWidget({
    Key key,
    @required this.child,
    @required this.appLockState,
  }) : super(key: key, child: child);

  final Widget child;
  final _AppLockState appLockState;

  @override
  bool updateShouldNotify(_ApplockInheritedWidget oldWidget) {
    return false;
  }
}
