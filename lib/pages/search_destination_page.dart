import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:users_app_uber/appInfo/app_info.dart';
import 'package:users_app_uber/global/global_const.dart';
import 'package:users_app_uber/methods/common_methods.dart';
import 'package:users_app_uber/models/address_model.dart';
import 'package:users_app_uber/models/prediction_model.dart';
import 'package:users_app_uber/widgets/loading_dialog.dart';
import 'package:users_app_uber/widgets/prediction_place_ui.dart';

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
      String apiPlacesUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:vn";
      var responseFromPlacesAPI = await CommonMethods.sendRequestToAPI(apiPlacesUrl);
      if (responseFromPlacesAPI == "error") {
        return;
      }
      if (responseFromPlacesAPI["status"] == "OK") {
        var predictionsJson = responseFromPlacesAPI["predictions"];
        var predictionsList = (predictionsJson as List).map((prediction) => PredictionModel.fromJson(prediction)).toList();
        setState(() {
          pickUpPredictionsPlacesList = predictionsList;

        });

      }
    }
  }

  void searchLocation(String locationName) async {
    clearPickupPredictions();
    if (locationName.length > 1) {
      String apiPlacesUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:vn";
      var responseFromPlacesAPI = await CommonMethods.sendRequestToAPI(apiPlacesUrl);
      if (responseFromPlacesAPI == "error") {
        return;
      }
      if (responseFromPlacesAPI["status"] == "OK") {
        var predictionResultInJson = responseFromPlacesAPI["predictions"];
        var predictionsList = (predictionResultInJson as List).map((eachPlacePrediction) => PredictionModel.fromJson(eachPlacePrediction)).toList();
        setState(() {
          dropOffPredictionsPlacesList = predictionsList;

        });

      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 10,
              child: Container(
                height: 230,
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, top: 48, right: 24, bottom: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {

                              Navigator.pop(context);
                            },
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Center(
                            child: Text(
                              "Set Dropoff Location",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Image.asset("assets/images/initial.png", height: 16, width: 16),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(5)),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: TextField(
                                  controller: pickUpTextEditingController,
                                  onChanged: (inputText) {
                                    searchPickupLocation(inputText);

                                  },
                                  decoration: const InputDecoration(
                                      hintText: "Your current location",
                                      fillColor: Colors.white12,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(left: 11, top: 9, bottom: 9)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Image.asset("assets/images/final.png", height: 16, width: 16),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(5)),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: TextField(
                                  controller: destinationTextEditingController,
                                  onChanged: (inputText) {
                                    searchLocation(inputText);
                                  },

                                  decoration: const InputDecoration(
                                      hintText: "Destination Address",
                                      fillColor: Colors.white12,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(left: 11, top: 9, bottom: 9)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Add "Confirm" button to confirm destination
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, "placeSelected");
              },
              child: const Text("Confirm Location"),
            ),

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
                        controller: pickUpTextEditingController, onPlaceSelected: clearPickupPredictions,
                      ),

                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 2),
                  itemCount: pickUpPredictionsPlacesList.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                ),
              ),
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
                        controller: destinationTextEditingController, onPlaceSelected: () {  },
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
