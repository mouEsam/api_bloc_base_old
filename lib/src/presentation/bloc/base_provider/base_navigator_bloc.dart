import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

abstract class BaseNavigatorBloc extends BaseCubit<NavigationState> {
  final GlobalKey<NavigatorState> navKey = GlobalKey();

  late final StreamSubscription _sub;

  get stream => super.stream.distinct();

  List<Stream> get eventsStreams;
  Map<Type, void Function(BuildContext, NavigationState)> get actions;

  BaseNavigatorBloc(NavigationState initialState) : super(initialState) {
    final combinedStream =
        CombineLatestStream(eventsStreams, generateNavigationState);
    final initialized = ensureInitialized()
        .asStream()
        .doOnData(onKeyInitialized)
        .asBroadcastStream(onCancel: (c) => c.cancel());
    _sub = initialized
        .switchMap((value) => combinedStream)
        .whereType<NavigationState>()
        .listen(emit);
    initialized.switchMap((value) => this.stream).listen(_handleState);
  }

  Future<void> onKeyInitialized(GlobalKey<NavigatorState> navKey) async {}

  Future<GlobalKey<NavigatorState>> ensureInitialized() async {
    if (navKey.currentContext != null) {
      return navKey;
    }
    await Future.doWhile(() async {
      await Future.delayed(Duration(microseconds: 1000), () {});
      return navKey.currentContext == null;
    });
    return navKey;
  }

  void _handleState(NavigationState event) {
    print("NavigationState ${event.runtimeType}");
    final type = event.runtimeType;
    final operation = actions[type];
    if (operation != null) {
      operation(navKey.currentContext!, event);
    }
  }

  Future<T?> pushDestructively<T>(String routeName) async {
    final key = await ensureInitialized();
    final result = await key.currentState!
        .pushNamedAndRemoveUntil(routeName, (r) => false);
    return result as T?;
  }

  Future<T?> push<T>(String routeName) async {
    final key = await ensureInitialized();
    final result = await key.currentState!.pushNamed(routeName);
    return result as T?;
  }

  NavigationState? generateNavigationState(List events);

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}

abstract class NavigationState extends Equatable implements Type {
  const NavigationState();
  @override
  get stringify => true;
  @override
  get props => [];
}
