import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';









class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late MapboxMapController _controller;

  @override
  void initState() {
    super.initState();
    // Set Mapbox access token at runtime

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
            onMapCreated: (controller) {
              setState(() {
                _controller = controller;
              });
            },
          ),
        ],
      ),
    );
  }
}


