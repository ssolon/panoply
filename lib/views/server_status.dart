import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:panoply/blocs/status_bloc.dart';

/// A status bar for our server connection

class ServerStatus extends StatelessWidget {
  const ServerStatus( {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatusBloc, StatusBlocState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text((state.source.isNotEmpty ? "${state.source}:" : "")+state.status),

          ],
        );
      }
    );
  }
}


