import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(Uygulamam());
}

class Uygulamam extends StatelessWidget {
  const Uygulamam({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: ('Nunito')),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo.shade200,
          centerTitle: true,
          title: Text(
            'Uygulamam',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        body: Text('merhaba'),
      ),
    );
  }
}
