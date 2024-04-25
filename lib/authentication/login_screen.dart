import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:users_app_uber/authentication/signup_screen.dart';

import '../global/global_const.dart';
import '../methods/common_methods.dart';
import '../pages/home_page.dart';
import '../widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {


  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods commonMethods = CommonMethods();
  checkIsNetWorkIsAvailable(){
    commonMethods.checkConnectivity(context);
    signInFormValidation();
  }
  signInFormValidation(){

    if(!emailTextEditingController.text.contains("@") || !emailTextEditingController.text.contains(".")){
      commonMethods.displaySnackBar("Email address is not valid", context);
    }
    else if(passwordTextEditingController.text.trim().length < 6){
      commonMethods.displaySnackBar("Password must be at least 6 characters", context);
    }
    else if(!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$').hasMatch(passwordTextEditingController.text.trim())){
      commonMethods.displaySnackBar("Password must include uppercase, lowercase, number, and special character", context);
    }

    else {
      signInUser();
    }

  }
  signInUser() async{
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Signing in..."),
    );

    final User? userFirebase=(
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailTextEditingController.text.trim(),
            password: passwordTextEditingController.text.trim()
        ).catchError((errorMsg)
        {
          Navigator.pop(context);
          commonMethods.displaySnackBar(errorMsg.toString(), context);
        })
    ).user;
    if(!context.mounted) return;
    Navigator.pop(context);
    if(userFirebase != null){
      //check if user exists
      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase.uid);
      usersRef.once().then((snapshot) {
        if (snapshot.snapshot.value != null) {
          //check if user is blocked
         if((snapshot.snapshot.value as Map)["blockStatus"] == "no"){
           userName = (snapshot.snapshot.value as Map)["name"];
           Navigator.push(context, MaterialPageRoute(builder: (context)=>HomePage()));
         }
         else{
           FirebaseAuth.instance.signOut();
           Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpScreen()));
           commonMethods.displaySnackBar("You are Blocked, Contact admin: admin@email.com", context);
         }
        }
        else{
          FirebaseAuth.instance.signOut();
          Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpScreen()));
          commonMethods.displaySnackBar("User does not exist", context);
        }
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                  children: [
                    Image.asset(
                      "assets/images/logo.png",
                    ),
                    Text(
                      "Login as a user",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                            children: [


                              TextField(
                                controller: emailTextEditingController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  prefixIcon: Icon(Icons.email),
                                  labelStyle: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey
                                ),

                              ),

                              const SizedBox(height: 22,),

                              TextField(
                                controller: passwordTextEditingController,
                                obscureText: true,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: Icon(Icons.lock),
                                  labelStyle: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey
                                ),

                              ),

                              const SizedBox(height: 32,),

                              ElevatedButton(
                                onPressed: (){
                                  checkIsNetWorkIsAvailable();


                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                                ),
                                child: const Text(
                                  "Sign In",
                                ),
                              ),

                            ]
                        )
                    ),
                    const SizedBox(height: 12,),
                    TextButton(
                      onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpScreen()));
                      },
                      child: const Text(
                          "Dont have an Account? Register here",
                          style: TextStyle(
                            color: Colors.grey,
                          )
                      ),
                    )

                  ]
              )
          ),
        )
    );
  }
}
