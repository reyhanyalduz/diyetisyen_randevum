import 'package:flutter/material.dart';
import '../utils/constants.dart';

Widget InfoCard(String title, String value) {
  return Container(
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.color1,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Wrap(
      children: [
        Text(title, style: TextStyle(color: Colors.white, fontSize: 12)),
        Text(' : '),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );
}