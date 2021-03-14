import 'package:flutter/material.dart';
import 'package:jasper/widgets/application-utils.dart';

Widget launcherIcon(String icon, Color color, Color iconColor, String appName,
    Widget executable, bool exists, BuildContext context) {
  return Container(
      width: 80,
      child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              ApplicationPage.routeName,
              arguments: ScreenArguments(color, executable, iconColor),
            );
          },
          child: new Column(children: [
            Opacity(
              opacity: exists ? 1.0 : 0.4,
              child: new Image.asset(
                icon,
                height: 50,
                width: 50,
                filterQuality: FilterQuality.high,
              ),
            ),
            new Padding(
                padding: EdgeInsets.only(top: 5),
                child: new Text(
                  appName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: new TextStyle(color: Colors.white),
                ))
          ])));
}

Widget drawerIcon(String icon, Color color, String executable) {
  return IconButton(
    icon: new Image.asset(icon),
    iconSize: 50,
    onPressed: () {
      print("hi");
    },
  );
}
