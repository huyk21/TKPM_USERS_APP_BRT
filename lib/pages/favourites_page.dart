import "package:firebase_database/firebase_database.dart";
import "package:flutter/material.dart";

import "../global/global_const.dart";
import "../models/address_model.dart";
import "add_new_location_page.dart";

class SavedPlacesPage extends StatefulWidget {
  const SavedPlacesPage({super.key});

  @override
  State<StatefulWidget> createState() => _SavedPlacesPageState();
}

class _SavedPlacesPageState extends State<SavedPlacesPage> {
  List<AddressModel> savedLocations = [];

  @override
  void initState() {
    super.initState();
    loadSavedLocations();
  }

  void onSave(AddressModel addressModel) {
    setState(() {
      savedLocations.add(addressModel);
    });
  }

  Future<void> loadSavedLocations() async {
    DatabaseReference dbRef =
        FirebaseDatabase.instance.ref().child("users").child(userID).child("saved_locations");
    DataSnapshot snapshot = await dbRef.get();

    if (snapshot.exists) {
      List<AddressModel> locations = [];
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        Map<String, dynamic> locationData = Map<String, dynamic>.from(value);
        locations.add(AddressModel.fromMap(locationData));
      });

      setState(() {
        savedLocations = locations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.indigoAccent,
      appBar: AppBar(
        title: const Text(
          "Saved Locations",
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
            color: Colors.grey,
          ),
        ),
      ),
      body: Column(
        children: [
          // Button to navigate to the new location page
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to the new page for adding a location
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NewLocationPage(onLocationSaved: onSave)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 24.0),
              ),
              child: const Text(
                "Add New Location",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),

          // List of saved locations
          Expanded(
            child: savedLocations.isNotEmpty
                ? ListView.builder(
                    itemCount: savedLocations.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          savedLocations[index].humanReadableAddress ?? '',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                        ),
                        subtitle: Text(
                          "${savedLocations[index].placeName ?? ''}\nLocation Type: ${savedLocations[index].tag}",
                          style:
                              const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        trailing:
                            const Icon(Icons.location_on, color: Colors.white),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      "No saved locations found.",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
