
/// Flutter bindings for ReduRx (A thin layer of a Redux-based state manager on
/// top of RxDart).
///
/// Nomi Modifications:
/// - Removed nullable property and the {return Container();} statement in
/// StreamBuilder, so that the library naturally supports null state objects and
/// rendering in slivers (containers throw errors)
/// - Added initialData in StreamBuilder so that initial builds don't throw null
/// before the stream completes. See
/// https://docs.flutter.io/flutter/widgets/StreamBuilder-class.html
library flutter_redurx;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:redurx/redurx.dart';

export 'package:redurx/redurx.dart';

/// Provider Widget to be on top of the App ([child]) providing the State from a given [store].
class Provider<T> extends InheritedWidget {
  Provider({
    Key key,
    @required Widget child,
    @required this.store,
  }) : super(key: key, child: child);
  final Store<T> store;

  /// Gets the Provider from a given [BuildContext].
  static Provider<T> of<T>(BuildContext context) =>
      context.inheritFromWidgetOfExactType(_targetType<Provider<T>>());

  static _targetType<T>() => T;

  /// Sugar to dispatch Actions on the Store in the Provider of the given [context].
  static Store<T> dispatch<T>(BuildContext context, ActionType action) =>
      Provider.of<T>(context).store.dispatch(action);

  /// We never trigger update, this is all up to ReduRx.
  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}

/// The Widget that connects the State to a [builder] function.
class Connect<S, P> extends StatefulWidget {
  /// [convert] is how you map the State to [builder] props.
  /// With [where] you can filter when the Widget should re-render, this is very important!
  /// If you want to handle [null] values on the [builder] by yourself, set [nullable] to [true].
  Connect({
    Key key,
    @required this.convert,
    @required this.where,
    @required this.builder,
    this.nullable = false,
  }) : super(key: key);

  final P Function(S state) convert;
  final bool Function(P oldState, P newState) where;
  final Widget Function(P state) builder;
  final bool nullable;

  @override
  _ConnectState createState() => _ConnectState<S, P>(where, builder);
}

class _ConnectState<S, P> extends State<Connect<S, P>> {
  _ConnectState(this.where, this.builder);

  final bool Function(P oldState, P newState) where;
  final Widget Function(P state) builder;

  P _prev;
  Store<S> _store;
  Stream<P> _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _store = Provider.of<S>(context).store;
    _stream = _store.stream
        .map<P>(widget.convert)
        .where((next) => widget.where(_prev, next));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<P>(
      initialData: widget.convert(Provider.of<S>(context).store.state),
      stream: _stream,
      builder: (context, snapshot) {
        _prev = snapshot.data;
        return builder(_prev);
      },
    );
  }
}
