import 'package:flutter_bloc/flutter_bloc.dart';

///
/// A place for status messages to be distributed.
///

abstract class StatusBlocBase {}

class StatusBlocEvent extends StatusBlocBase {
  final String source;
  final String status;

  StatusBlocEvent(this.source, this.status);
}

class StatusBlocUpdatedStatusEvent extends StatusBlocEvent {
  StatusBlocUpdatedStatusEvent(String source, String status):super(source, status);
}

abstract class StatusBlocState {
  String get source;
  String get status;
}

class StatusBlocInitialState extends StatusBlocState {
  String get source => '';
  String get status => '';
}

class StatusBlocUpdateStatusState extends StatusBlocState {
  final String source;
  final String status;

  StatusBlocUpdateStatusState(this.source, this.status);
}

class StatusBloc extends Bloc<StatusBlocEvent, StatusBlocState> {
  StatusBloc():super(StatusBlocInitialState());

  @override
  Stream<StatusBlocState> mapEventToState(StatusBlocEvent event) async* {
    yield StatusBlocUpdateStatusState(event.source, event.status);
  }

}


