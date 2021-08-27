

import 'package:flutter/material.dart';
import 'package:panoply/models/header.dart';
import 'package:flutter_number_picker/flutter_number_picker.dart';

final GlobalKey<State<FetchCriteriaView>> fetchCriteriaViewStateKey =
GlobalKey<State<FetchCriteriaView>>();

class FetchCriteriaView extends StatefulWidget {
  const FetchCriteriaView({Key? key}) : super(key: key);

  @override
  CriteriaState createState() => CriteriaState();
}

class CriteriaState extends State<FetchCriteriaView> {
  FetchOp? _fetchType = FetchOp.lastNHeaders;
  int _numberDays = 7;
  int _numberHeaders = 10;

  FetchCriteria getCriteria() => FetchCriteria(
    _fetchType!,
    numberOfDays: _numberDays,
    numberOfHeaders: _numberHeaders
  );

  void _typeChanged(FetchOp? value) {
    setState( () {
      _fetchType = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: const Text("Get the last N days' headers:"),
          leading: Radio<FetchOp> (
            value: FetchOp.lastNDays,
            groupValue: _fetchType,
            onChanged: null, //_typeChanged,
          ),
          trailing: CustomNumberPicker(
              initialValue: _numberDays,
              maxValue: 100,
              minValue: 1,
              step: 1,
              enable: _fetchType == FetchOp.lastNDays,
              onValue: (value) {
                setState( () {
                  _numberDays = value as int;
                });
                return value;
              },
          )
        ),

        ListTile(
          title: const Text("Get new headers"),
          leading: Radio<FetchOp> (
            value: FetchOp.newHeaders,
            groupValue: _fetchType,
            onChanged: null, // _typeChanged,
          )
        ),
        ListTile(
          title: const Text("Get all headers"),
          leading: Radio<FetchOp> (
            value: FetchOp.allHeaders,
            groupValue: _fetchType,
            onChanged: _typeChanged,
          ),
    ),
          ListTile(
            title: const Text("Get the latest N headers"),
            leading: Radio<FetchOp>(
              value: FetchOp.lastNHeaders,
              groupValue: _fetchType,
              onChanged: _typeChanged,
            ),
          trailing: CustomNumberPicker (
            initialValue: _numberHeaders,
            maxValue: 10000,
            minValue: 1,
            step: 1,
            enable: _fetchType == FetchOp.lastNHeaders,
            onValue: (value) {
              setState(() {
                _numberHeaders = value as int;
              });
            }
          ),
        ),
      ]
    );
  }
}
