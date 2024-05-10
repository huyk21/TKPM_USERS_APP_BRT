import 'package:flutter/cupertino.dart';
import 'package:users_app_uber/models/address_model.dart';

class AppInfo extends ChangeNotifier
{
  AddressModel? pickUpLocation;
  AddressModel? dropOffLocation;
  AddressModel? savedLocation;

  void updatePickUpLocation(AddressModel pickUpModel)
  {
    pickUpLocation = pickUpModel;
    notifyListeners();
  }

  void updateDropOffLocation(AddressModel dropOffModel)
  {
    dropOffLocation = dropOffModel;
    notifyListeners();
  }

  void updateSavedLocation(AddressModel savedModel) {
    savedLocation = savedModel;
    notifyListeners();
  }
}