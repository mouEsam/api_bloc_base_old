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
  Map<NavigationState, void Function(BuildContext)> get actions;

  BaseNavigatorBloc(NavigationState initialState) : super(initialState) {
    final combinedStream =
        CombineLatestStream(eventsStreams, generateNavigationState);
    final initialized = ensureInitialized()
        .asStream()
        .asBroadcastStream(onCancel: (c) => c.cancel());
    _sub = initialized
        .switchMap((value) => combinedStream)
        .whereType<NavigationState>()
        .listen(emit);
    initialized.switchMap((value) => this.stream).listen(_handleState);
  }

  Future<void> ensureInitialized() async {
    await Future.doWhile(() async {
      await Future.delayed(Duration(microseconds: 1000), () {});
      return navKey.currentContext == null;
    });
    return;
  }

  void _handleState(NavigationState event) {
    print("NavigationState ${event.runtimeType}");
    final operation = actions[event];
    if (operation != null) {
      operation(navKey.currentContext!);
    }
  }

  Future pushDestructively(BuildContext context, String routeName) async {
    final result = await Navigator.pushNamedAndRemoveUntil(
        context, routeName, (r) => false);
    return result;
  }

  NavigationState? generateNavigationState(List events);

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}

abstract class NavigationState extends Equatable {
  @override
  get stringify => true;
  @override
  get props => [];
}
