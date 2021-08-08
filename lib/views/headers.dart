

import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';

class HeaderList extends StatefulWidget {
  const HeaderList({Key? key, required this.group}) : super(key: key);

  final String group;

  @override
  State<HeaderList> createState() => _HeaderListState();
}

class _HeaderListState extends State<HeaderList> with UiLoggy {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to first route when tapped.
            Navigator.pop(context);
          },
          child: Text('Go back!'),
        ),
      ),
    );
  }
}