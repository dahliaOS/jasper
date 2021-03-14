import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'widgets/sliding_up_panel.dart';
import 'widgets/launcher.dart';
import 'widgets/application-utils.dart';
import 'package:flutter/services.dart';
//APPLCATION IMPORTS
import 'applications/authenticator/main.dart';
import 'applications/calculator/calculator.dart';
import 'applications/clock/main.dart';
import 'applications/containers/containers.dart';
import 'applications/developer/developer.dart';
import 'applications/editor/editor.dart';
import 'applications/files/main.dart';
import 'applications/logging/logging.dart';
import 'applications/messages/main.dart';
import 'applications/monitor/monitor.dart';
import 'applications/terminal/main.dart';
import 'applications/terminal/root/main.dart';
import 'applications/welcome/welcome.dart';

void main() {
  runApp(new Jasper());
  SystemChrome.setEnabledSystemUIOverlays([]);
}

class Jasper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'jasper',
      theme: new ThemeData(
        platform: TargetPlatform.fuchsia,
        primarySwatch: Colors.deepOrange,
      ),
      home: new JasperHomePage(),
      routes: {
        ApplicationPage.routeName: (context) => ApplicationPage(),
      },
    );
  }
}

class JasperHomePage extends StatefulWidget {
  JasperHomePage({Key key}) : super(key: key);
  @override
  _JasperHomePageState createState() => new _JasperHomePageState();
}

class _JasperHomePageState extends State<JasperHomePage> {
  String _timeString;
  String _dateString;
  @override
  void initState() {
    _timeString = _formatDateTime(DateTime.now());
    _dateString = _formatDate(DateTime.now());
    Timer.periodic(Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }

  BorderRadiusGeometry radius = BorderRadius.only(
    topLeft: Radius.circular(10.0),
    topRight: Radius.circular(10.0),
  );

  bool wideMode = false;

  double _width() {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1920) {
      wideMode ? 100 : 350;
    } else if (width >= 1500 && width < 1920) {
      wideMode ? 80 : 250;
    } else if (width >= 1200 && width < 1500) {
      wideMode ? 50 : 100;
    } else if (width < 1200) {
      wideMode ? 20 : 50;
    } else if (width < 600) {
      wideMode ? 10 : 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/wallpapers/wp.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: new Stack(
          children: [
            new Positioned(
              left: 0.0,
              right: 0.0,
              top: 0.0,
              height: 20,
              child: Container(
                  color: Colors.black.withOpacity(0.75),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: new Icon(
                          Icons.signal_cellular_4_bar,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 1),
                        child: new Icon(
                          Icons.signal_wifi_4_bar,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: new Icon(
                          Icons.battery_charging_full,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: new Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Text(
                          _timeString,
                          style: new TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  )),
            ),
            new Padding(
              padding: EdgeInsets.only(top: 20, bottom: 75),
              child: new Column(
                children: [
                  new Center(
                    child: new Column(
                      children: [
                        new Container(
                          height: 100,
                        ),
                        Text(
                          _timeString,
                          style: new TextStyle(
                            color: Colors.white,
                            fontSize: 80,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          _dateString,
                          style: new TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SlidingUpPanel(
                color: Colors.black.withOpacity(0.75),
                borderRadius: radius,
                panel: new Column(children: [
                  new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      new Container(
                        height: 10,
                      ),
                      new Center(
                        child: Container(
                          padding: EdgeInsets.only(top: 5, bottom: 5),
                          height: 5,
                          width: 50,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                        ),
                      ),
                      new Center(
                          child: Container(
                        height: 70,
                        child: Wrap(
                          spacing: 10.0,
                          children: [
                            drawerIcon('assets/images/icons/PNG/calculator.png',
                                Colors.red, "executable"),
                            drawerIcon(
                                'assets/images/icons/PNG/note_mobile.png',
                                Colors.red,
                                "executable"),
                            drawerIcon('assets/images/icons/PNG/terminal.png',
                                Colors.red, "executable"),
                            drawerIcon('assets/images/icons/PNG/logs.png',
                                Colors.red, "executable"),
                            drawerIcon('assets/images/icons/PNG/developer.png',
                                Colors.red, "executable"),
                          ],
                        ),
                      ))
                    ],
                  ),
                  new Center(
                    child: new Container(
                        height: 25,
                        width: 100,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        child: new Center(
                          child: Text(
                            "ALL APPS",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        )),
                  ),
                  new Expanded(
                    child: new SingleChildScrollView(
                      child: new Container(
                          padding: EdgeInsets.only(top: 15),
                          child: Wrap(spacing: 15.0, children: [
                            launcherIcon(
                                "assets/images/icons/PNG/authenticator.png",
                                Colors.red,
                                Colors.white,
                                "Authenticator",
                                Calculator(),
                                false,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/calculator.png",
                                Colors.green,
                                Colors.white,
                                "Calculator",
                                Calculator(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/clock.png",
                                Colors.blue[900],
                                Colors.white,
                                "Clock",
                                Clock(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/containers.png",
                                Colors.blue[700],
                                Colors.white,
                                "Containers",
                                Containers(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/developer.png",
                                Colors.red[700],
                                Colors.white,
                                "Developer Options",
                                DeveloperApp(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/disks.png",
                                Colors.red[700],
                                Colors.white,
                                "Disks",
                                DeveloperApp(),
                                false,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/files.png",
                                Colors.deepOrange[700],
                                Colors.white,
                                "Files",
                                Files(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/help.png",
                                Colors.deepOrange[700],
                                Colors.white,
                                "Help",
                                Files(),
                                false,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/logs.png",
                                Colors.red[700],
                                Colors.white,
                                "Logs",
                                Logs(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/messages.png",
                                Colors.purple[700],
                                Colors.white,
                                "Messages",
                                Messages(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/files.png",
                                Colors.deepOrange[700],
                                Colors.white,
                                "Music",
                                Files(),
                                false,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/note_mobile.png",
                                Colors.amber[700],
                                Colors.white,
                                "Notes",
                                TextEditorApp(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/photos.png",
                                Colors.deepOrange[700],
                                Colors.white,
                                "Media",
                                Files(),
                                false,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/root.png",
                                Colors.red[700],
                                Colors.white,
                                "Root Terminal",
                                RootTerminalApp(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/settings.png",
                                Colors.deepOrange[700],
                                Colors.white,
                                "Settings",
                                DeveloperApp(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/terminal.png",
                                Colors.grey[900],
                                Colors.white,
                                "Terminal",
                                TerminalApp(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/theme.png",
                                Colors.deepOrange[700],
                                Colors.white,
                                "Theme Demo",
                                Files(),
                                true,
                                context),
                            launcherIcon(
                                "assets/images/icons/PNG/welcome-info.png",
                                Colors.white,
                                Colors.black,
                                "Welcome",
                                Welcome(),
                                true,
                                context),
                          ])),
                    ),
                  )
                ])),
            new Positioned(
                left: 0.0,
                right: 0.0,
                bottom: 0.0,
                height: 15,
                child: new Container(
                    color: Colors.black,
                    child: new Center(
                      child: Container(
                        padding: EdgeInsets.only(top: 5, bottom: 5),
                        height: 5,
                        width: 120,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                      ),
                    ))),
          ],
        ) /* add child content here */,
      ),
    );
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

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, LLLL d').format(dateTime);
  }
}
