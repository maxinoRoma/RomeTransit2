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

  @override
  void initState() {
    super.initState();
    InitDB();
    requestLocation();
    _mapController = MapController();
  }

  InitDB() async {
    String data = await rootBundle.loadString("assets/data/stops.json");
    final result = await json.decode(data)
    
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
                duration: Duration(milliseconds: 1000),
                showTwoGlows: false,
                repeat: true,
                endRadius: 250,
                child:
                    CircleAvatar(backgroundColor: Colors.blueGrey, radius: 5),
              )));
      _mapController.move(gpsPosition, 19);

      setState(() {});
    });
  }

  moveToGPS() {
    _mapController.move(gpsPosition, 19);
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
          panel: Center(child: Text("CENTRO")),
          body: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
                center: LatLng(0, 0),
                zoom: 30,
                keepAlive: true,
                interactiveFlags: InteractiveFlag.all),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                maxZoom: 30,
                retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
                tileSize: 256,
              ),
              MarkerLayer(
                markers: gpsMarker,
              )
            ],
          )),
    );
  }
}
