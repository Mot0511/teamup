import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: Text('Teamup', style: Theme.of(context).textTheme.headlineLarge)
            )
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(strokeWidth: 7)
              )
            )
          )
        ],
      )
    );
  }
}