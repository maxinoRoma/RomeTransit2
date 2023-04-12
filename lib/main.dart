import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:path/path.dart';

void main() => runApp(romeTransitApp());

class romeTransitApp extends StatelessWidget {
  const romeTransitApp({super.key});
  static const String _title = 'Flutter Stateful Clicker Counter';
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.
  // This class is the configuration for the state.
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final MapController _mapController;
  late final LatLng gpsPosition;
  var gpsMarker = <Marker>[];
  var markList = <Marker>[];
  String txtCenter = "CENTER";
  List<dynamic> stops = [];
  List<dynamic> near = [];

  @override
  void initState() {
    super.initState();
    initDB();
    requestLocation();
    _mapController = MapController();
  }

  initDB() async {
    stops = await loadData("stops.txt");
  }

  Future<List> loadData(String file) async {
    String data = await rootBundle.loadString(join("assets/data/", file));
    var res = CsvToListConverter().convert(data, eol: "\n");
    List<dynamic> ret = res;
    ret.removeAt(0);
    return ret;
  }

  requestLocation() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else if (Platform.isIOS) {
        exit(0);
      }
    }
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            forceAndroidLocationManager: true)
        .then((Position position) {
      gpsMarker.clear();
      gpsPosition = LatLng(position.latitude, position.longitude);

      gpsMarker.add(Marker(
          point: gpsPosition,
          builder: (context) => AvatarGlow(
                glowColor: Colors.blueGrey,
                duration: Duration(milliseconds: 1500),
                showTwoGlows: false,
                repeat: true,
                endRadius: 2000,
                child:
                    CircleAvatar(backgroundColor: Colors.blueGrey, radius: 10),
              )));
      _mapController.move(gpsPosition, 17);
      getNearStops(500);
      drawNearMarker();
      setState(() {});
    });
  }

  getNearStops(int meter) {
    var distance = new Distance();
    stops.forEach((element) {
      double lat = element[4];
      double lng = element[5];
      var d = distance.as(LengthUnit.Meter, gpsPosition, LatLng(lat, lng));
      if (d < meter) {
        near.add(element);
      }
    });
  }

  drawNearMarker() {
    if (near.length == 0) {
      return;
    }
    markList.clear();
    for (var element in near) {
      double lat = element[4];
      double lng = element[5];

      var m = Marker(
          point: LatLng(lat, lng),
          builder: (context) => Container(
                padding:
                    EdgeInsets.only(bottom: 16, right: 0, left: 16, top: 0),
                child: Icon(
                  Icons.place,
                  color: Colors.red,
                  size: 38,
                ),
              ));

      markList.add(m);
    }
    setState(() {});
  }

  moveToGPS() {
    _mapController.move(gpsPosition, 17);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: SlidingUpPanel(
          header: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            width: MediaQuery.of(context).size.width,
            height: 80,
            child: BottomNavigationBar(
              elevation: 20,
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              ],
              iconSize: 32,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.blueGrey,
            ),
          ),
          panel: Center(child: Text("$txtCenter")),
          backdropOpacity: 0.3,
          backdropEnabled: true,
          backdropColor: Colors.black,
          body: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
                center: LatLng(0, 0),
                zoom: 18,
                keepAlive: true,
                interactiveFlags: InteractiveFlag.all),
            children: [
              TileLayer(
                //urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',

                maxZoom: 18,
                maxNativeZoom: 18,
                retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
              ),
              MarkerLayer(
                markers: gpsMarker,
              ),
              MarkerLayer(
                markers: markList,
              )
            ],
          )),
    );
  }
}
