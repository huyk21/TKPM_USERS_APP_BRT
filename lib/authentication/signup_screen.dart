import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:users_app_uber/authentication/login_screen.dart';
import 'package:users_app_uber/methods/common_methods.dart';
import 'package:users_app_uber/pages/home_page.dart';

import '../widgets/loading_dialog.dart';
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  TextEditingController usernameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods commonMethods = CommonMethods();
  checkIsNetWorkIsAvailable(){
    commonMethods.checkConnectivity(context);
    signUpFormValidation();
  }
  signUpFormValidation(){
    if(usernameTextEditingController.text.trim().length < 3){
      commonMethods.displaySnackBar("Username must be at least 3 characters", context);
    }
    else if(!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(usernameTextEditingController.text.trim())) {
      commonMethods.displaySnackBar("Username can only contain alphanumeric characters and underscores", context);
    }
    else if(phoneTextEditingController.text.trim().length < 7){
      commonMethods.displaySnackBar("Phone number must be at least 7 characters", context);
    }
    else if(!RegExp(r'^\d+$').hasMatch(phoneTextEditingController.text.trim())){
      commonMethods.displaySnackBar("Phone number can only contain digits", context);
    }
    else if(!emailTextEditingController.text.contains("@") || !emailTextEditingController.text.contains(".")){
      commonMethods.displaySnackBar("Email address is not valid", context);
    }
    else if(passwordTextEditingController.text.trim().length < 6){
      commonMethods.displaySnackBar("Password must be at least 6 characters", context);
    }
    else if(!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$').hasMatch(passwordTextEditingController.text.trim())){
      commonMethods.displaySnackBar("Password must include uppercase, lowercase, number, and special character", context);
    }

    else {
      registerNewUser();
    }

  }
  registerNewUser() async{
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Registering New User"),
    );
    final User? userFirebase=(
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase!.uid);
    Map userDataMap = {
      "name": usernameTextEditingController.text.trim(),
      "email": emailTextEditingController.text.trim(),
      "phone": phoneTextEditingController.text.trim(),
      "id": userFirebase.uid,
      "isTongDai": "no",
      "blockStatus": "no",
    };

    usersRef.set(userDataMap);
    Navigator.push(context, MaterialPageRoute(builder: (context)=>const HomePage()));


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
                "assets/images/BRT_logo.jpeg",
              ),
              const Text(
                "Create a User Account",
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
                          controller: usernameTextEditingController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: "User Name",
                            prefixIcon: Icon(Icons.person),
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
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email Address",
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
                      controller: phoneTextEditingController,
                        keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone),
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
                      decoration: const InputDecoration(
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
                            "Sign Up",
                          ),
                        ),

                  ]
                )
              ),
              const SizedBox(height: 12,),
              TextButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>const LoginScreen()));
                },
                child: const Text(
                  "Already have an account?",
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
