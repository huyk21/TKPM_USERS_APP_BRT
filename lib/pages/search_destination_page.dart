import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:users_app_uber/appInfo/app_info.dart';
import 'package:users_app_uber/methods/common_methods.dart';
import 'package:users_app_uber/models/address_model.dart';
import 'package:users_app_uber/models/prediction_model.dart';
import 'package:users_app_uber/widgets/loading_dialog.dart';
import 'package:users_app_uber/widgets/prediction_place_ui.dart';

import '../global/global_const.dart';

class SearchDestinationPage extends StatefulWidget {
  final String? initialPlaceID;

  const SearchDestinationPage({super.key, this.initialPlaceID});

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController =
      TextEditingController();
  List<PredictionModel> dropOffPredictionsPlacesList = [];
  List<PredictionModel> pickUpPredictionsPlacesList = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Fetch place details after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPlaceID != null) {
        fetchClickedPlaceDetails(widget.initialPlaceID!);
      }
    });
  }

  // Method to fetch place details based on the given placeID
  Future<void> fetchClickedPlaceDetails(String placeID) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Getting details..."),
    );

    String urlPlaceDetailsAPI =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$googleMapKey";
    var responseFromPlaceDetailsAPI =
        await CommonMethods.sendRequestToAPI(urlPlaceDetailsAPI);

    Navigator.pop(context); // Close the loading dialog

    if (responseFromPlaceDetailsAPI == "error" ||
        responseFromPlaceDetailsAPI["status"] != "OK") {
      return;
    }

    // Extract the place details
    AddressModel location = AddressModel();
    location.placeName = responseFromPlaceDetailsAPI["result"]["name"];
    location.latitudePosition =
        responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lat"];
    location.longitudePosition =
        responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lng"];
    location.placeID = placeID;

    // Update the destination field with the retrieved data
    setState(() {
      destinationTextEditingController.text = location.placeName ?? "";
    });

    // Update global drop-off location
    Provider.of<AppInfo>(context, listen: false)
        .updateDropOffLocation(location);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Destination set to ${location.placeName}")),
    );
  }

  // Clear pickup predictions
  void clearPickupPredictions() {
    setState(() {
      pickUpPredictionsPlacesList = [];
    });
  }

  // Logic for pickup location search
  void searchPickupLocation(String locationName) async {
    if (locationName.length > 1) {
      String apiPlacesUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:vn";
      var responseFromPlacesAPI =
          await CommonMethods.sendRequestToAPI(apiPlacesUrl);
      if (responseFromPlacesAPI != "error" &&
          responseFromPlacesAPI["status"] == "OK") {
        var predictionsJson = responseFromPlacesAPI["predictions"];
        var predictionsList = (predictionsJson as List)
            .map((prediction) => PredictionModel.fromJson(prediction))
            .toList();
        setState(() {
          pickUpPredictionsPlacesList = predictionsList;
        });
      }
    }
  }

  // Logic for destination location search
  void searchDestinationLocation(String locationName) async {
    clearPickupPredictions();
    if (locationName.length > 1) {
      String apiPlacesUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:vn";
      var responseFromPlacesAPI =
          await CommonMethods.sendRequestToAPI(apiPlacesUrl);
      if (responseFromPlacesAPI != "error" &&
          responseFromPlacesAPI["status"] == "OK") {
        var predictionResultInJson = responseFromPlacesAPI["predictions"];
        var predictionsList = (predictionResultInJson as List)
            .map((eachPlacePrediction) =>
                PredictionModel.fromJson(eachPlacePrediction))
            .toList();
        setState(() {
          dropOffPredictionsPlacesList = predictionsList;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Dropoff Location"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Text field for "Your current location"
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.place, color: Colors.green),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextField(
                      controller: pickUpTextEditingController,
                      onChanged: searchPickupLocation,
                      decoration: const InputDecoration(
                        hintText: "Your current location",
                        fillColor: Colors.grey,
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Text field for "Destination Address"
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.place, color: Colors.red),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextField(
                      controller: destinationTextEditingController,
                      onChanged: searchDestinationLocation,
                      decoration: const InputDecoration(
                        hintText: "Destination Address",
                        fillColor: Colors.grey,
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Add "Confirm" button to confirm destination
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, "placeSelected");
              },
              child: const Text("Confirm Locations"),
            ),
            // Pickup predictions list (if available)
            if (pickUpPredictionsPlacesList.isNotEmpty)

            // For pickup predictions
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3,
                      child: PredictionPlaceUI(
                        predictedPlaceData: pickUpPredictionsPlacesList[index],
                        isPickup: true,  // Here we pass true for pickup locations
                        controller: pickUpTextEditingController,
                      ),

                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 2),
                  itemCount: pickUpPredictionsPlacesList.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                ),
              ),

            // Drop-off predictions list (if available)
            if (dropOffPredictionsPlacesList.isNotEmpty)
            // For drop-off predictions
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3,
                      child: PredictionPlaceUI(
                        predictedPlaceData: dropOffPredictionsPlacesList[index],
                        isPickup: false,  // And false for drop-off locations
                        controller: destinationTextEditingController,
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 2),
                  itemCount: dropOffPredictionsPlacesList.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                ),
              ),

          ],
        ),
      ),
    );
  }

}
