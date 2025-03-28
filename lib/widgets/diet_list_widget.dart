import 'package:flutter/material.dart';
import '../utils/constants.dart';

Widget BuildDietList() {
  List<String> meals = [
    'Kahvaltı',
    'Ara Öğün',
    'Öğle Yemeği',
    'Akşam Yemeği'
  ];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Diyet Listesi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Column(
        children: meals
            .map((meal) => Card(
          color: AppColors.color4,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(meal, style: TextStyle(fontSize: 18)),
          ),
        ))
            .toList(),
      ),
    ],
  );
}

