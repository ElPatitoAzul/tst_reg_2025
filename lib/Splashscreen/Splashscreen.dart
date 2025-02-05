
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';

import '../form/Register.dart';

class Spashscreen extends StatefulWidget {
  const Spashscreen({Key? key}) : super(key: key);

  @override
  _SpashscreenState createState() => _SpashscreenState();
}

class _SpashscreenState extends State<Spashscreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Lottie.asset('assets/House.json'),
      nextScreen: RegistroForm(),
      splashIconSize: 250,
      duration: 700,
      splashTransition: SplashTransition.rotationTransition,
      pageTransitionType: PageTransitionType.leftToRightWithFade,
      animationDuration: const Duration(seconds: 5),
    );
  }
}
