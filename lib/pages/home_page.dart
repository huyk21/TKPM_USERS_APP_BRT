import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:users_app_uber/authentication/login_screen.dart';
import 'package:users_app_uber/global/global_const.dart';
import 'package:users_app_uber/global/trip_var.dart';
import 'package:users_app_uber/methods/common_methods.dart';
import 'package:users_app_uber/methods/manage_drivers_methods.dart';
import 'package:users_app_uber/methods/push_notification_service.dart';
import 'package:users_app_uber/models/direction_details.dart';
import 'package:users_app_uber/models/online_nearby_drivers.dart';
import 'package:users_app_uber/pages/about_page.dart';
import 'package:users_app_uber/pages/search_destination_page.dart';
import 'package:users_app_uber/pages/trips_history_page.dart';
import 'package:users_app_uber/widgets/info_dialog.dart';

import '../appInfo/app_info.dart';
import '../widgets/loading_dialog.dart';


class HomePage extends StatefulWidget
{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage>
{
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 276;
  double bottomMapPadding = 0;
  double rideDetailsContainerHeight = 0;
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;
  DirectionDetails? tripDirectionDetailsInfo;
  List<LatLng> polylineCoOrdinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  bool isDrawerOpened = true;
  String stateOfApp = "normal";
  bool nearbyOnlineDriversKeysLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  DatabaseReference? tripRequestRef;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;


  makeDriverNearbyCarIcon()
  {
    if(carIconNearbyDriver == null)
    {
      ImageConfiguration configuration = createLocalImageConfiguration(context, size: const Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(configuration, "assets/images/tracking.png").then((iconImage)
      {
        carIconNearbyDriver = iconImage;
      });
    }
  }

  getCurrentLiveLocationOfUser() async
  {
    Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng positionOfUserInLatLng = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    CameraPosition cameraPosition = CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    await CommonMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(currentPositionOfUser!, context);

    await getUserInfoAndCheckBlockStatus();

    await initializeGeoFireListener();
  }

  getUserInfoAndCheckBlockStatus() async
  {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid);

    await usersRef.once().then((snap)
    {
      if(snap.snapshot.value != null)
      {
        if((snap.snapshot.value as Map)["blockStatus"] == "no")
        {
          setState(() {
            userName = (snap.snapshot.value as Map)["name"];
            isTongDai = (snap.snapshot.value as Map)["isTongDai"];
            userPhone = (snap.snapshot.value as Map)["phone"];
          });
        }
        else
        {
          FirebaseAuth.instance.signOut();

          Navigator.push(context, MaterialPageRoute(builder: (c)=> const LoginScreen()));

          cMethods.displaySnackBar("You are blocked. Contact our admin at: BeRightThere@gmail.com", context);
        }
      }
      else
      {
        FirebaseAuth.instance.signOut();
        Navigator.push(context, MaterialPageRoute(builder: (c)=> const LoginScreen()));
      }
    });
  }

  displayUserRideDetailsContainer() async
  {
    ///Directions API
    await retrieveDirectionDetails();

    setState(() {
      searchContainerHeight = 0;
      bottomMapPadding = 240;
      rideDetailsContainerHeight = 242;
      isDrawerOpened = false;
    });
  }

  retrieveDirectionDetails() async
  {
    var pickUpLocation = Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    var pickupGeoGraphicCoOrdinates = LatLng(pickUpLocation!.latitudePosition!, pickUpLocation.longitudePosition!);
    var dropOffDestinationGeoGraphicCoOrdinates = LatLng(dropOffDestinationLocation!.latitudePosition!, dropOffDestinationLocation.longitudePosition!);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageText: "Getting direction..."),
    );

    ///Directions API
    var detailsFromDirectionAPI = await CommonMethods.getDirectionDetailsFromAPI(pickupGeoGraphicCoOrdinates, dropOffDestinationGeoGraphicCoOrdinates);
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });

    Navigator.pop(context);

    //draw route from pickup to dropOffDestination
    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickUpToDestination = pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodedPoints!);

    polylineCoOrdinates.clear();
    if(latLngPointsFromPickUpToDestination.isNotEmpty)
    {
      latLngPointsFromPickUpToDestination.forEach((PointLatLng latLngPoint)
      {
        polylineCoOrdinates.add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
      });
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId("polylineID"),
        color: Colors.pink,
        points: polylineCoOrdinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    //fit the polyline into the map
    LatLngBounds boundsLatLng;
    if(pickupGeoGraphicCoOrdinates.latitude > dropOffDestinationGeoGraphicCoOrdinates.latitude
        && pickupGeoGraphicCoOrdinates.longitude > dropOffDestinationGeoGraphicCoOrdinates.longitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: dropOffDestinationGeoGraphicCoOrdinates,
        northeast: pickupGeoGraphicCoOrdinates,
      );
    }
    else if(pickupGeoGraphicCoOrdinates.longitude > dropOffDestinationGeoGraphicCoOrdinates.longitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(pickupGeoGraphicCoOrdinates.latitude, dropOffDestinationGeoGraphicCoOrdinates.longitude),
        northeast: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude, pickupGeoGraphicCoOrdinates.longitude),
      );
    }
    else if(pickupGeoGraphicCoOrdinates.latitude > dropOffDestinationGeoGraphicCoOrdinates.latitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude, pickupGeoGraphicCoOrdinates.longitude),
        northeast: LatLng(pickupGeoGraphicCoOrdinates.latitude, dropOffDestinationGeoGraphicCoOrdinates.longitude),
      );
    }
    else
    {
      boundsLatLng = LatLngBounds(
        southwest: pickupGeoGraphicCoOrdinates,
        northeast: dropOffDestinationGeoGraphicCoOrdinates,
      );
    }

    controllerGoogleMap!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    //add markers to pickup and dropOffDestination points
    Marker pickUpPointMarker = Marker(
      markerId: const MarkerId("pickUpPointMarkerID"),
      position: pickupGeoGraphicCoOrdinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: pickUpLocation.placeName, snippet: "Pickup Location"),
    );

    Marker dropOffDestinationPointMarker = Marker(
      markerId: const MarkerId("dropOffDestinationPointMarkerID"),
      position: dropOffDestinationGeoGraphicCoOrdinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(title: dropOffDestinationLocation.placeName, snippet: "Destination Location"),
    );

    setState(() {
      markerSet.add(pickUpPointMarker);
      markerSet.add(dropOffDestinationPointMarker);
    });

    //add circles to pickup and dropOffDestination points
    Circle pickUpPointCircle = Circle(
      circleId: const CircleId('pickupCircleID'),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: pickupGeoGraphicCoOrdinates,
      fillColor: Colors.pink,
    );

    Circle dropOffDestinationPointCircle = Circle(
      circleId: const CircleId('dropOffDestinationCircleID'),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: dropOffDestinationGeoGraphicCoOrdinates,
      fillColor: Colors.pink,
    );

    setState(() {
      circleSet.add(pickUpPointCircle);
      circleSet.add(dropOffDestinationPointCircle);
    });
  }

  resetAppNow()
  {
    setState(() {
      polylineCoOrdinates.clear();
      polylineSet.clear();
      markerSet.clear();
      circleSet.clear();
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      searchContainerHeight = 276;
      bottomMapPadding = 300;
      isDrawerOpened = true;

      status = "";
      nameDriver = "";
      photoDriver = "";
      phoneNumberDriver = "";
      carDetailsDriver = "";
      tripStatusDisplay = 'Driver is Arriving';
    });
  }

  cancelRideRequest()
  {
    //remove ride request from database
    tripRequestRef!.remove();

    setState(() {
      stateOfApp = "normal";
    });
  }

  displayRequestContainer()
  {
    setState(() {
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 220;
      bottomMapPadding = 200;
      isDrawerOpened = true;
    });

    //send ride request
    makeTripRequest();
  }

  updateAvailableNearbyOnlineDriversOnMap()
  {
    setState(() {
      markerSet.clear();
    });

    Set<Marker> markersTempSet = <Marker>{};

    for(OnlineNearbyDrivers eachOnlineNearbyDriver in ManageDriversMethods.nearbyOnlineDriversList)
    {
      LatLng driverCurrentPosition = LatLng(eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.lngDriver!);

      Marker driverMarker = Marker(
        markerId: MarkerId("driver ID = ${eachOnlineNearbyDriver.uidDriver}"),
        position: driverCurrentPosition,
        icon: carIconNearbyDriver!,
      );

      markersTempSet.add(driverMarker);
    }

    setState(() {
      markerSet = markersTempSet;
    });
  }

  Future<String?> getVehicleType(String driverKey) async {
    try {
      DatabaseReference driverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(driverKey);

      DatabaseEvent event = await driverRef.once();
      DataSnapshot snap = event.snapshot;

      if (snap.exists) {
        Map data = snap.value as Map;
        if (data.containsKey("car_details") && data["car_details"].containsKey("vehicle_type")) {
          return data["car_details"]["vehicle_type"] as String;
        } else {
          if (kDebugMode) {
            print("car_details or vehicle_type field is missing for this driver");
          }
        }
      } else {
        if (kDebugMode) {
          print("Driver with key $driverKey does not exist.");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching vehicle type: $error');
      }
    }

    return null;
  }

  initializeGeoFireListener()
  {
    Geofire.initialize("onlineDrivers");
    Geofire.queryAtLocation(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude, 22)!
        .listen((driverEvent)
    async {
      if(driverEvent != null)
      {
        var onlineDriverChild = driverEvent["callBack"];
        String driverKey = driverEvent["key"];
        String? type = await getVehicleType(driverKey);
        
        switch(onlineDriverChild)
        {
          case Geofire.onKeyEntered:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            onlineNearbyDrivers.vehicleType = type;
            ManageDriversMethods.nearbyOnlineDriversList.add(onlineNearbyDrivers);


              //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();


            break;

          case Geofire.onKeyExited:
            ManageDriversMethods.removeDriverFromList(driverEvent["key"]);

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;

          case Geofire.onKeyMoved:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            onlineNearbyDrivers.vehicleType = type;
            ManageDriversMethods.updateOnlineNearbyDriversLocation(onlineNearbyDrivers);

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;

          case Geofire.onGeoQueryReady:
            nearbyOnlineDriversKeysLoaded = true;

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;
        }
      }
    });
  }

  makeTripRequest()
  {
    tripRequestRef = FirebaseDatabase.instance.ref().child("tripRequests").push();

    var pickUpLocation = Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    Map pickUpCoOrdinatesMap =
    {
      "latitude": pickUpLocation!.latitudePosition.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };

    Map dropOffDestinationCoOrdinatesMap =
    {
      "latitude": dropOffDestinationLocation!.latitudePosition.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
    };

    Map driverCoOrdinates =
    {
      "latitude": "",
      "longitude": "",
    };

    Map dataMap =
    {
      "tripID": tripRequestRef!.key,
      "publishDateTime": DateTime.now().toString(),

      "userName": userName,
      "userPhone": userPhone,
      "userID": userID,
      "pickUpLatLng": pickUpCoOrdinatesMap,
      "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
      "pickUpAddress": pickUpLocation.placeName,
      "dropOffAddress": dropOffDestinationLocation.placeName,

      "driverID": "waiting",
      "carDetails": "",
      "driverLocation": driverCoOrdinates,
      "driverName": "",
      "driverPhone": "",
      "driverPhoto": "",
      "fareAmount": "",
      "vehicleType": "",
      "status": "new",
    };

    tripRequestRef!.set(dataMap);

    tripStreamSubscription = tripRequestRef!.onValue.listen((eventSnapshot) async
    {
      if(eventSnapshot.snapshot.value == null)
      {
        return;
      }

      if((eventSnapshot.snapshot.value as Map)["vehicleType"] != null)
      {
        vehicleType = (eventSnapshot.snapshot.value as Map)["vehicleType"];
      }

      if((eventSnapshot.snapshot.value as Map)["driverName"] != null)
      {
        nameDriver = (eventSnapshot.snapshot.value as Map)["driverName"];
      }

      if((eventSnapshot.snapshot.value as Map)["driverPhone"] != null)
      {
        phoneNumberDriver = (eventSnapshot.snapshot.value as Map)["driverPhone"];
      }

      if((eventSnapshot.snapshot.value as Map)["driverPhoto"] != null)
      {
        photoDriver = (eventSnapshot.snapshot.value as Map)["driverPhoto"];
      }

      if((eventSnapshot.snapshot.value as Map)["carDetails"] != null)
      {
        carDetailsDriver = (eventSnapshot.snapshot.value as Map)["carDetails"];
      }

      if((eventSnapshot.snapshot.value as Map)["status"] != null)
      {
        status = (eventSnapshot.snapshot.value as Map)["status"];
      }

      if((eventSnapshot.snapshot.value as Map)["driverLocation"] != null)
      {
        double driverLatitude = double.parse((eventSnapshot.snapshot.value as Map)["driverLocation"]["latitude"].toString());
        double driverLongitude = double.parse((eventSnapshot.snapshot.value as Map)["driverLocation"]["longitude"].toString());
        LatLng driverCurrentLocationLatLng = LatLng(driverLatitude, driverLongitude);

        if(status == "accepted")
        {
          //update info for pickup to user on UI
          //info from driver current location to user pickup location
          updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
        }
        else if(status == "arrived")
        {
          //update info for arrived - when driver reach at the pickup point of user
          setState(() {
            tripStatusDisplay = 'Driver has Arrived';
          });
        }
        else if(status == "ontrip")
        {
          //update info for dropoff to user on UI
          //info from driver current location to user dropoff location
          updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng);
        }
      }

      if(status == "accepted")
      {
        displayTripDetailsContainer();

        Geofire.stopListener();

        //remove drivers markers
        setState(() {
          markerSet.removeWhere((element) => element.markerId.value.contains("driver"));
        });
      }

      if(status == "ended")
      {
        // if((eventSnapshot.snapshot.value as Map)["fareAmount"] != null)
        // {
        //   double fareAmount = double.parse((eventSnapshot.snapshot.value as Map)["fareAmount"].toString());

          // var responseFromPaymentDialog = await showDialog(
          //   context: context,
          //   builder: (BuildContext context) => PaymentDialog(fareAmount: fareAmount.toString()),
          // );

          // if(responseFromPaymentDialog == "paid")
          // {
            tripRequestRef!.onDisconnect();
            tripRequestRef = null;

            tripStreamSubscription!.cancel();
            tripStreamSubscription = null;

            resetAppNow();
            Restart.restartApp();
          // }
        // }
      }
    });
  }

  displayTripDetailsContainer()
  {
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 291;
      bottomMapPadding = 281;
    });
  }

  updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async
  {
    if(!requestingDirectionDetailsInfo)
    {
      requestingDirectionDetailsInfo = true;

      var userPickUpLocationLatLng = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      var directionDetailsPickup = await CommonMethods.getDirectionDetailsFromAPI(driverCurrentLocationLatLng, userPickUpLocationLatLng);

      if(directionDetailsPickup == null)
      {
        return;
      }

      setState(() {
        tripStatusDisplay = "Driver is Coming - ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng) async
  {
    if(!requestingDirectionDetailsInfo)
    {
      requestingDirectionDetailsInfo = true;

      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation;
      var userDropOffLocationLatLng = LatLng(dropOffLocation!.latitudePosition!, dropOffLocation.longitudePosition!);

      var directionDetailsPickup = await CommonMethods.getDirectionDetailsFromAPI(driverCurrentLocationLatLng, userDropOffLocationLatLng);

      if(directionDetailsPickup == null)
      {
        return;
      }

      setState(() {
        tripStatusDisplay = "Driving to DropOff Location - ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  noDriverAvailable()
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => InfoDialog(
          title: "No Driver Available",
          description: "No driver found in the nearby location. Please try again shortly.",
        )
    );
  }

  searchDriver()
  {
    if(availableNearbyOnlineDriversList!.isEmpty)
    {
      cancelRideRequest();
      resetAppNow();
      noDriverAvailable();
      return;
    }

    var currentDriver = availableNearbyOnlineDriversList![0];

    //send notification to this currentDriver - currentDriver means selected driver
    sendNotificationToDriver(currentDriver);

    availableNearbyOnlineDriversList!.removeAt(0);
  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver)
  {
    //update driver's newTripStatus - assign tripID to current driver
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("newTripStatus");

    currentDriverRef.set(tripRequestRef!.key);

    //get current driver device recognition token
    DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("deviceToken");

    tokenOfCurrentDriverRef.once().then((dataSnapshot)
    {
      if(dataSnapshot.snapshot.value != null)
      {
        String deviceToken = dataSnapshot.snapshot.value.toString();

        //send notification
        PushNotificationService.sendNotificationToSelectedDriver(
            deviceToken,
            context,
            tripRequestRef!.key.toString()
        );
      }
      else
      {
        return;
      }

      const oneTickPerSec = Duration(seconds: 1);

      var timerCountDown = Timer.periodic(oneTickPerSec, (timer)
      {
        requestTimeoutDriver = requestTimeoutDriver - 1;

        //when trip request is not requesting means trip request cancelled - stop timer
        if(stateOfApp != "requesting")
        {
          timer.cancel();
          currentDriverRef.set("cancelled");
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;
        }

        //when trip request is accepted by online nearest available driver
        currentDriverRef.onValue.listen((dataSnapshot)
        {
          if(dataSnapshot.snapshot.value.toString() == "accepted")
          {
            timer.cancel();
            currentDriverRef.onDisconnect();
            requestTimeoutDriver = 20;
          }
        });

        //if 20 seconds passed - send notification to next nearest online available driver
        if(requestTimeoutDriver == 0)
        {
          currentDriverRef.set("timeout");
          timer.cancel();
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;

          //send notification to next nearest online available driver
          searchDriver();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context)
  {
    makeDriverNearbyCarIcon();

    return Scaffold(
      key: sKey,
      drawer: Container(
        width: 255,
        color: Colors.black87,
        child: Drawer(
          backgroundColor: Colors.white10,
          child: ListView(
            children: [

              const Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),

              //header
              Container(
                color: Colors.black54,
                height: 160,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                  ),
                  child: Row(
                    children: [

                      Image.asset(
                        "assets/images/avatarman.png",
                        width: 60,
                        height: 60,
                      ),

                      const SizedBox(width: 16,),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4,),

                          const Text(
                            "Profile",
                            style: TextStyle(
                              color: Colors.white38,
                            ),
                          ),

                        ],
                      ),

                    ],
                  ),
                ),
              ),

              const Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),

              const SizedBox(height: 10,),

              //body
              GestureDetector(
                onTap: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (c)=> const TripsHistoryPage()));
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.history, color: Colors.grey,),
                  ),
                  title: const Text("History", style: TextStyle(color: Colors.grey),),
                ),
              ),

              GestureDetector(
                onTap: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (c)=> const AboutPage()));
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.info, color: Colors.grey,),
                  ),
                  title: const Text("About", style: TextStyle(color: Colors.grey),),
                ),
              ),

              GestureDetector(
                onTap: ()
                {
                  FirebaseAuth.instance.signOut();

                  Navigator.push(context, MaterialPageRoute(builder: (c)=> const LoginScreen()));
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: (){},
                    icon: const Icon(Icons.logout, color: Colors.grey,),
                  ),
                  title: const Text("Logout", style: TextStyle(color: Colors.grey),),
                ),
              ),

            ],
          ),
        ),
      ),
      body: Stack(
        children: [

          ///google map
          GoogleMap(
            padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            polylines: polylineSet,
            markers: markerSet,
            circles: circleSet,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController)
            {
              controllerGoogleMap = mapController;

              googleMapCompleterController.complete(controllerGoogleMap);

              setState(() {
                bottomMapPadding = 300;
              });

              getCurrentLiveLocationOfUser();
            },
          ),

          ///drawer button
          Positioned(
            top: 36,
            left: 19,
            child: GestureDetector(
              onTap: ()
              {
                if(isDrawerOpened == true)
                {
                  sKey.currentState!.openDrawer();
                }
                else
                {
                  resetAppNow();
                  Restart.restartApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const
                  [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 20,
                  child: Icon(
                    isDrawerOpened == true ? Icons.menu : Icons.close,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          ///search location icon button
          Positioned(
            left: 0,
            right: 0,
            bottom: -80,
            child: SizedBox(
              height: searchContainerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [

                  ElevatedButton(
                    onPressed: () async
                    {
                      var responseFromSearchPage = await Navigator.push(context, MaterialPageRoute(builder: (c)=> const SearchDestinationPage()));

                      if(responseFromSearchPage == "placeSelected")
                      {
                        displayUserRideDetailsContainer();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24)
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),

                  // ElevatedButton(
                  //   onPressed: () {},
                  //   style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.grey,
                  //       shape: const CircleBorder(),
                  //       padding: const EdgeInsets.all(24)
                  //   ),
                  //   child: const Icon(
                  //     Icons.home,
                  //     color: Colors.white,
                  //     size: 25,
                  //   ),
                  // ),
                  //
                  // ElevatedButton(
                  //   onPressed: () {},
                  //   style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.grey,
                  //       shape: const CircleBorder(),
                  //       padding: const EdgeInsets.all(24)
                  //   ),
                  //   child: const Icon(
                  //     Icons.work,
                  //     color: Colors.white,
                  //     size: 25,
                  //   ),
                  // ),

                ],
              ),
            ),
          ),

          ///ride details container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: rideDetailsContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white12,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(.7, .7),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // First Card with GestureDetector
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          stateOfApp = "requesting";
                        });

                        displayRequestContainer();
                        availableNearbyOnlineDriversList = ManageDriversMethods.nearbyOnlineDriversList;
                        availableNearbyOnlineDriversList?.retainWhere((element) => element.vehicleType == "Car");
                        searchDriver();
                      },
                      child: Card(
                        elevation: 10,
                        color: Colors.black45,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tripDirectionDetailsInfo != null ? "${tripDirectionDetailsInfo!.durationTextString} - ${tripDirectionDetailsInfo!.distanceTextString}" : "",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Image.asset(
                                "assets/images/uberexec.png",
                                height: 100,
                                width: 100,
                              ),
                              Text(
                                tripDirectionDetailsInfo != null ? "\$${(cMethods.calculateFareAmount(tripDirectionDetailsInfo!)).toString()}" : "",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Second Card with GestureDetector (Duplicate of the first for symmetry)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          stateOfApp = "requesting";
                        });

                        displayRequestContainer();
                        availableNearbyOnlineDriversList = ManageDriversMethods.nearbyOnlineDriversList;
                        availableNearbyOnlineDriversList?.retainWhere((element) => element.vehicleType == "Bike");
                        searchDriver();
                      },
                      child: Card(
                        elevation: 10,
                        color: Colors.black45,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tripDirectionDetailsInfo != null ? "${tripDirectionDetailsInfo!.durationTextString} - ${tripDirectionDetailsInfo!.distanceTextString}" : "",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Image.asset(
                                "assets/images/bike.png",
                                height: 100,
                                width: 100,
                              ),
                              Text(
                                tripDirectionDetailsInfo != null ? "\$${(cMethods.calculateFareAmount(tripDirectionDetailsInfo!)).toString()}" : "",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),






          ///request container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: requestContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                boxShadow:
                [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    const SizedBox(height: 12,),

                    SizedBox(
                      width: 200,
                      child: LoadingAnimationWidget.flickr(
                        leftDotColor: Colors.greenAccent,
                        rightDotColor: Colors.pinkAccent,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 20,),

                    GestureDetector(
                      onTap: ()
                      {
                        resetAppNow();
                        cancelRideRequest();
                        Restart.restartApp();
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(width: 1.5, color: Colors.grey),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

          ///trip details container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: tripContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                boxShadow:
                [
                  BoxShadow(
                    color: Colors.white24,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 5,),

                    //trip status display text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tripStatusDisplay,
                          style: const TextStyle(fontSize: 19, color: Colors.grey,),
                        ),
                      ],
                    ),

                    const SizedBox(height: 19,),

                    const Divider(
                      height: 1,
                      color: Colors.white70,
                      thickness: 1,
                    ),

                    const SizedBox(height: 19,),

                    //image - driver name and driver car details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        ClipOval(
                          child: Image.network(
                            photoDriver == ''
                                ? "https://firebasestorage.googleapis.com/v0/b/flutter-uber-clone-with-admin.appspot.com/o/avatarman.png?alt=media&token=7a04943c-a566-45d3-b820-d33da3b105c7"
                                : photoDriver,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(width: 8,),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(nameDriver, style: const TextStyle(fontSize: 20, color: Colors.grey,),),

                            Text(carDetailsDriver, style: const TextStyle(fontSize: 14, color: Colors.grey,),),

                          ],
                        ),

                      ],
                    ),

                    const SizedBox(height: 19,),

                    const Divider(
                      height: 1,
                      color: Colors.white70,
                      thickness: 1,
                    ),

                    const SizedBox(height: 19,),

                    //call driver btn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        GestureDetector(
                          onTap: ()
                          {
                            launchUrl(Uri.parse("tel://$phoneNumberDriver"));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [

                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                                  border: Border.all(
                                    width: 1,
                                    color: Colors.white,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 11,),

                              const Text("Call", style: TextStyle(color: Colors.grey,),),

                            ],
                          ),
                        ),

                      ],
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
