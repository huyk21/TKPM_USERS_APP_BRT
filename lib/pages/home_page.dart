import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final MapboxMapController _controller;
  late Position currentPositionOfUser;

 getCurrentLiveLocationOfUser () async{
   Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
   currentPositionOfUser = positionOfUser;
   LatLng positonOfUser = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
   CameraPosition cameraPosition = CameraPosition(target: positonOfUser, zoom: 14);
   _controller!.moveCamera(CameraUpdate.newCameraPosition(cameraPosition));
 }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapboxMap(
            accessToken: 'pk.eyJ1IjoiaHV5azIxIiwiYSI6ImNsbnpzcWhycTEwbnYybWxsOTAydnc2YmYifQ.55__cADsvmLEm7G1pib5nA', // Use the access token
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.42796133580664, -122.085749655962),
              zoom: 14.4746,
            ),
            styleString: 'mapbox://styles/mapbox/streets-v12',
            onMapCreated: (controller) {
              setState(() {
                _controller = controller;
              }

              );
              getCurrentLiveLocationOfUser();
            },
          ),
        ],
      ),
    );
  }
}


