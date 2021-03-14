import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ScreenArguments {
  final Color color;
  final Widget launchItem;
  final Color iconColor;

  ScreenArguments(this.color, this.launchItem, this.iconColor);
}

class ApplicationPage extends StatefulWidget {
  ApplicationPage({Key key}) : super(key: key);
  @override
  _ApplicationPageState createState() => new _ApplicationPageState();
  static const routeName = '/extractArguments';
}

class _ApplicationPageState extends State<ApplicationPage> {
  String _timeString;
  @override
  void initState() {
    _timeString = _formatDateTime(DateTime.now());
    Timer.periodic(Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }

  BorderRadiusGeometry radius = BorderRadius.only(
    topLeft: Radius.circular(10.0),
    topRight: Radius.circular(10.0),
  );

  @override
  @override
  Widget build(BuildContext context) {
    final ScreenArguments args = ModalRoute.of(context).settings.arguments;

    return Scaffold(
        backgroundColor: args.color,
        body: new Column(
          children: [
            Container(
                height: 20,
                color: args.color,
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: new Icon(
                        Icons.signal_cellular_4_bar,
                        color: args.iconColor,
                        size: 16,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 1),
                      child: new Icon(
                        Icons.signal_wifi_4_bar,
                        color: args.iconColor,
                        size: 16,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: new Icon(
                        Icons.battery_charging_full,
                        color: args.iconColor,
                        size: 16,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: new Icon(
                        Icons.warning,
                        color: args.iconColor,
                        size: 16,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Text(
                        _timeString,
                        style: new TextStyle(color: args.iconColor),
                      ),
                    ),
                  ],
                )),
            new Expanded(child: ClipRect(child: args.launchItem)),
            new GestureDetector(
                onPanUpdate: (details) {
                  if (details.delta.dy < 0) Navigator.pop(context);
                },
                child: Container(
                    height: 15,
                    color: args.color,
                    child: new Center(
                      child: Container(
                        padding: EdgeInsets.only(top: 5, bottom: 5),
                        height: 5,
                        width: 120,
                        decoration: BoxDecoration(
                            color: args.iconColor,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                      ),
                    )))
          ],
        ));
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    setState(() {
      _timeString = formattedDateTime;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('h:mm').format(dateTime);
  }
}
