import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:users_app_uber/appInfo/app_info.dart';

import '../global/global_const.dart';
import '../methods/common_methods.dart';
import '../models/address_model.dart';
import '../models/prediction_model.dart';
import '../widgets/prediction_place_ui.dart';

class NewLocationPage extends StatefulWidget {
  const NewLocationPage({super.key, required this.onLocationSaved});
  final ValueChanged<AddressModel> onLocationSaved;

  @override
  State<StatefulWidget> createState() => _NewLocationPageState();
}

class _NewLocationPageState extends State<NewLocationPage> {
  final TextEditingController tagTextEditingController =
      TextEditingController();
  final TextEditingController locationTextEditingController =
      TextEditingController();
  final DatabaseReference databaseReference =
      FirebaseDatabase.instance.ref().child("users").child(userID).child("saved_locations");
  List<PredictionModel> predictionsPlacesList = [];

  void clearPredictions() {
    setState(() {
      predictionsPlacesList = [];
    });
  }

  void searchLocation(String locationName) async {
    if (locationName.length > 1) {
      String apiPlacesUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:vn";
      var responseFromPlacesAPI =
          await CommonMethods.sendRequestToAPI(apiPlacesUrl);
      if (responseFromPlacesAPI == "error") {
        return;
      }
      if (responseFromPlacesAPI["status"] == "OK") {
        var predictionsJson = responseFromPlacesAPI["predictions"];
        var predictionsList = (predictionsJson as List)
            .map((prediction) => PredictionModel.fromJson(prediction))
            .toList();
        setState(() {
          predictionsPlacesList = predictionsList;
        });
      }
    }
  }

  void saveNewLocation() async {
    String tag = tagTextEditingController.text.trim();
    var savedLocation = Provider.of<AppInfo>(context, listen: false).savedLocation;

    savedLocation?.tag = tag;
    // Make sure savedLocation is not null before accessing its properties
    if (savedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location data is not available")),
      );
      return;
    }

    double? lat = savedLocation.latitudePosition;
    double? long = savedLocation.longitudePosition;
    String? placeName = savedLocation.placeName;

    // Validate required fields
    if (tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // Generate a new key for the new location
    String newKey = databaseReference.push().key ?? "";

    // Create the data to save
    Map<String, dynamic> locationData = {
      "tag": tag,
      "placeName": placeName,
      "latitude": lat,
      "longitude": long,
    };

    // Save the location data to Firebase Realtime Database
    databaseReference.child(newKey).set(locationData).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location saved successfully!")),
      );
      widget.onLocationSaved(savedLocation);
      Navigator.pop(context); // Navigate back after saving
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving location: $error")),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.indigoAccent,
      appBar: AppBar(
        title: const Text(
          "Add New Location",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tag text field
            TextField(
              controller: tagTextEditingController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: "Set A Catchy Reminder (e.g., Home, Work)",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(
                      color: Colors.white,
                      // White border when the field is not focused
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(
                      color: Colors.white,
                      // White border when the field is focused
                      width: 2,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  labelStyle: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 28.0),

            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(5)),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: TextField(
                        controller: locationTextEditingController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (inputText) {
                          searchLocation(inputText);
                        },
                        decoration: const InputDecoration(
                          labelText: "Choose the location",
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                            borderSide: BorderSide(
                              color: Colors.white,
                              // White border when the field is not focused
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                            borderSide: BorderSide(
                              color: Colors.white,
                              // White border when the field is focused
                              width: 2,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),

            if (predictionsPlacesList.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 3, horizontal: 1),
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3,
                      child: PredictionPlaceUI(
                        predictedPlaceData: predictionsPlacesList[index],
                        isSavedLocation: true,
                        controller: locationTextEditingController,
                        onPlaceSelected: clearPredictions,
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 2),
                  itemCount: predictionsPlacesList.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                ),
              ),

            const SizedBox(height: 25.0),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: saveNewLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 24.0),

                ),
                child: const Text(
                  "Add Location",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
