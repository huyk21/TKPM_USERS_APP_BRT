import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../global/global_const.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;

  void _onMapCreated(GoogleMapController controller) {

    controllerGoogleMap = controller;


    googleMapCompleterController.complete(controllerGoogleMap);


  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: _onMapCreated,
          ),

        ],
    ),
    );
  }
}


