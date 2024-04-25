import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
class CommonMethods{
  checkConnectivity(BuildContext context) async{
    var connectivityResult = await (Connectivity().checkConnectivity());
    if(connectivityResult != ConnectivityResult.mobile && connectivityResult != ConnectivityResult.wifi){
      if(!context.mounted)return;
      displaySnackBar("Your device is not connected to internet. Please check your internet connection", context);
    }

  }
  displaySnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}