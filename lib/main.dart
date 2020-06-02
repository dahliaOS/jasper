import 'package:flutter/material.dart';

void main() {
  runApp(new MyApp());
}
class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Generated App',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2196f3),
        accentColor: const Color(0xFF2196f3),
        canvasColor: const Color(0xFFfafafa),
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
    @override
    Widget build(BuildContext context) {
      return new Scaffold(
        body: Container(
            color: Color(0xff7f3c3c),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(
                  height: 20,
                  color: Color(0xb3000000),
                  child: Container(
                      width: 100, height: 2, color: Color(0xffffffff))),
              Container(height: 50, color: Color(0xb0ffffff), child: Row())
            ])));
    }
}

