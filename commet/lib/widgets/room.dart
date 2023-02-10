import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class Room extends StatelessWidget {
  const Room({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SizedBox(
        height: 50,
        width: 300,
        child: TextButton(
          onPressed: () {
            print("ADHASKDJ");
          },
          child: const Text('TextButton'),
        ),
      ),
    );
  }
}
