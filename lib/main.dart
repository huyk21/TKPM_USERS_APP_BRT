import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:users_app_uber/appInfo/app_info.dart';
import 'package:users_app_uber/authentication/login_screen.dart';
import 'package:users_app_uber/pages/home_page.dart';


Future<void>main() async {


  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBZ2XV4A8wn-qTTOGQLnPu5cAuXdIXiHeQ',
        appId: '1:832713560007:android:8cd12b1b74fba1478953e2',
        messagingSenderId: '832713560007',
        projectId: 'be-right-there-f7e78',
        databaseURL: 'https://be-right-there-f7e78-default-rtdb.asia-southeast1.firebasedatabase.app',
      )
  );
  await Permission.locationWhenInUse.isDenied.then((value) {
    if(value){
      Permission.locationWhenInUse.request();
    }
  });
  runApp(const MyApp());

}

class MyApp extends StatelessWidget
{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context)
  {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        title: 'Flutter User App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
        ),
        home: FirebaseAuth.instance.currentUser == null ? const LoginScreen() : const HomePage(),
      ),
    );
  }
}


