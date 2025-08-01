
import 'package:flutter/material.dart';

Future<dynamic> launchCheckoutCompleteScreen(BuildContext context) {
  return Navigator.of(context).push(MaterialPageRoute(builder: (context) => CompleteScreen(), fullscreenDialog: true));
}

class CompleteScreen extends StatelessWidget {
  const CompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //create screen that shows the truck has been sold
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Checkout Completed'),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
