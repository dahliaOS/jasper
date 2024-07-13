import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.lightGreen, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const Jasper(title: 'Flutter Demo Home Page'),
    );
  }
}

enum ColorItem {
  red('red', Colors.red),
  orange('orange', Colors.orange),
  yellow('yellow', Colors.yellow),
  green('green', Colors.green),
  blue('blue', Colors.blue),
  indigo('indigo', Colors.indigo),
  violet('violet', Color(0xFF8F00FF)),
  purple('purple', Colors.purple),
  pink('pink', Colors.pink),
  silver('silver', Color(0xFF808080)),
  gold('gold', Color(0xFFFFD700)),
  beige('beige', Color(0xFFF5F5DC)),
  brown('brown', Colors.brown),
  grey('grey', Colors.grey),
  black('black', Colors.black),
  white('white', Colors.white);

  const ColorItem(this.label, this.color);
  final String label;
  final Color color;
}

class SearchAnchors extends StatefulWidget {
  const SearchAnchors({super.key});

  @override
  State<SearchAnchors> createState() => _SearchAnchorsState();
}

class _SearchAnchorsState extends State<SearchAnchors> {
  String? selectedColor;
  List<ColorItem> searchHistory = <ColorItem>[];

  Iterable<Widget> getHistoryList(SearchController controller) {
    return searchHistory.map((color) => ListTile(
          leading: const Icon(Icons.history),
          title: Text(color.label),
          trailing: IconButton(
              icon: const Icon(Icons.call_missed),
              onPressed: () {
                controller.text = color.label;
                controller.selection =
                    TextSelection.collapsed(offset: controller.text.length);
              }),
          onTap: () {
            controller.closeView(color.label);
            handleSelection(color);
          },
        ));
  }

  Iterable<Widget> getSuggestions(SearchController controller) {
    final String input = controller.value.text;
    return ColorItem.values
        .where((color) => color.label.contains(input))
        .map((filteredColor) => ListTile(
              leading: CircleAvatar(backgroundColor: filteredColor.color),
              title: Text(filteredColor.label),
              trailing: IconButton(
                  icon: const Icon(Icons.call_missed),
                  onPressed: () {
                    controller.text = filteredColor.label;
                    controller.selection =
                        TextSelection.collapsed(offset: controller.text.length);
                  }),
              onTap: () {
                controller.closeView(filteredColor.label);
                handleSelection(filteredColor);
              },
            ));
  }

  void handleSelection(ColorItem color) {
    setState(() {
      selectedColor = color.label;
      if (searchHistory.length >= 5) {
        searchHistory.removeLast();
      }
      searchHistory.insert(0, color);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SearchAnchor.bar(
          isFullScreen: false,
          viewConstraints:
              const BoxConstraints(minWidth: 360.0, maxHeight: 530.0),
          barHintText: 'Search apps, web, and more...',
          suggestionsBuilder: (context, controller) {
            if (controller.text.isEmpty) {
              if (searchHistory.isNotEmpty) {
                return getHistoryList(controller);
              }
              return <Widget>[
                const Center(
                  child: Text('\nNo search history.',
                      style: TextStyle(color: Colors.grey)),
                )
              ];
            }
            return getSuggestions(controller);
          },
        ),
        const SizedBox(height: 20),
        if (selectedColor == null)
          const Text('No recent activity')
        else
          Text('Last selected color is $selectedColor')
      ],
    );
  }
}

class LauncherAppIcon extends StatelessWidget {
  const LauncherAppIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [FlutterLogo(), Text("Jasper")],
      ),
    );
  }
}

class Jasper extends StatefulWidget {
  const Jasper({super.key, required this.title});

  final String title;

  @override
  State<Jasper> createState() => _JasperState();
}

class _JasperState extends State<Jasper> {
//  int _counter = 0;
  late String _timeString;
  void _incrementCounter() {
    setState(() {
      // _counter++;
    });
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

  void initState() {
    _timeString = _formatDateTime(DateTime.now());
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Container(
            decoration: const BoxDecoration(
          image: DecorationImage(
            image:
                AssetImage("assets/vadim-sherbakov-NQSWvyVRIJk-unsplash.jpg"),
            fit: BoxFit.cover,
          ),
        )),
        Positioned(
            bottom: 0,
            child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25.0),
                  topRight: Radius.circular(25.0),
                ),
                child: Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: 8.0,
                          sigmaY: 8.0,
                        ),
                        child: Container(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondary
                                .withOpacity(0.9),
                            child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 5,
                                  right: 5,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    IconButton.filledTonal(
                                        onPressed: () {
                                          showModalBottomSheet<void>(
                                            barrierColor: Colors.transparent,
                                            showDragHandle: true,
                                            context: context,
                                            // TODO: Remove when this is in the framework https://github.com/flutter/flutter/issues/118619
                                            constraints: const BoxConstraints(
                                                maxWidth: 620,
                                                minHeight: 605,
                                                maxHeight: 605),
                                            builder: (context) {
                                              return SizedBox(
                                                height: 620,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 32.0),
                                                  child: ListView(
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    children: const [
                                                      SearchAnchors(),
                                                      Row(
                                                        children: [
                                                          LauncherAppIcon(),
                                                          LauncherAppIcon(),
                                                          LauncherAppIcon()
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.brightness_5)),
                                    Row(
                                      children: [
                                        FlutterLogo(),
                                        FlutterLogo(),
                                        FlutterLogo(),
                                        FlutterLogo()
                                      ],
                                    ),
                                    SizedBox(
                                        height: 40,
                                        child: FilledButton.tonal(
                                            onPressed: () {},
                                            child: Row(children: [
                                              const Icon(Icons.developer_board),
                                              Container(
                                                width: 5,
                                              ),
                                              const Icon(
                                                  Icons.settings_ethernet),
                                              Container(
                                                width: 8,
                                              ),
                                              Container(
                                                width: 2,
                                                height: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                              ),
                                              Container(
                                                width: 8,
                                              ),
                                              Text(_timeString)
                                            ])))
                                  ],
                                ))),
                      ),
                    ],
                  ),
                )))
      ],
    ));
  }
}
