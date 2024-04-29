import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
String googleMapKey = "AIzaSyDuDxriw8CH8NbVLiXtKFQ2Nb64AoRSdyg";
const CameraPosition MapboxPlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);




String userPhone = "";
String userID = FirebaseAuth.instance.currentUser!.uid;
String serverKeyFCM = "key=AAAAweGYj8c:APA91bHPCnM4FG3KMn_jc1lyZhE1aPTKW6p1-twv2PeO2Qkd6AbyGf3vnTfhP-bj5B-U7nX7flyr9clyc9XH2D15I7oygMScSj4MV5-GIpTzkzCcLPb5B9TJGh1BSVJ51DCPOdjTRcWq";

const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);

