import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:users_app_uber/appInfo/app_info.dart';
import 'package:users_app_uber/global/global_const.dart';
import 'package:users_app_uber/global/trip_var.dart';
import 'package:users_app_uber/methods/common_methods.dart';
import 'package:users_app_uber/models/address_model.dart';
import 'package:users_app_uber/models/prediction_model.dart';
import 'package:users_app_uber/widgets/loading_dialog.dart';

class PredictionPlaceUI extends StatefulWidget {
  PredictionModel? predictedPlaceData;
  late final bool isPickup;
  late final TextEditingController controller;
  PredictionPlaceUI({super.key, this.predictedPlaceData, this.isPickup = false, required this.controller});

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}


class _PredictionPlaceUIState extends State<PredictionPlaceUI>
{
  ///Place Details - Places API
  void fetchClickedPlaceDetails(String placeID) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageText: "Getting details..."),
    );

    String urlPlaceDetailsAPI = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$googleMapKey";
    var responseFromPlaceDetailsAPI = await CommonMethods.sendRequestToAPI(urlPlaceDetailsAPI);

    pickUp = responseFromPlaceDetailsAPI["result"]["name"];
    Navigator.pop(context); // Close the loading dialog

    if (responseFromPlaceDetailsAPI == "error") {
      return;
    }

    if (responseFromPlaceDetailsAPI["status"] == "OK") {
      AddressModel location = AddressModel();
      location.placeName = responseFromPlaceDetailsAPI["result"]["name"];
      location.latitudePosition = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lat"];
      location.longitudePosition = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lng"];
      location.placeID = placeID;

      if (widget.isPickup) {
        Provider.of<AppInfo>(context, listen: false).updatePickUpLocation(location);
        widget.controller.text = location.placeName ?? "";
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Pickup location updated to ${location.placeName}"))
        );

      } else {
        Provider.of<AppInfo>(context, listen: false).updateDropOffLocation(location);
        Navigator.pop(context, "placeSelected");
      }


    }
  }


  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: ()
      {
        fetchClickedPlaceDetails(widget.predictedPlaceData!.place_id.toString());



      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
      ),
      child: SizedBox(
        child: Column(
          children: [

            const SizedBox(height: 10,),

            Row(
              children: [

                const Icon(
                  Icons.share_location,
                  color: Colors.grey,
                ),

                const SizedBox(width: 13,),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [

                      Text(
                        widget.predictedPlaceData!.main_text.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 3,),

                      Text(
                        widget.predictedPlaceData!.secondary_text.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),

                    ],
                  ),
                ),

              ],
            ),

            const SizedBox(height: 10,),

          ],
        ),
      ),
    );
  }
}
