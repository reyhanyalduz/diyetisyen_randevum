import 'package:flutter/material.dart';

import '../models/user.dart';
import 'bmi_chart_widget.dart';
import 'info_card_widget.dart';

class MeasurementsSectionWidget extends StatelessWidget {
  final Client client;
  final VoidCallback onMeasurementTap;

  const MeasurementsSectionWidget({
    Key? key,
    required this.client,
    required this.onMeasurementTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: InfoCard('VKİ', '${client.bmi.toStringAsFixed(2)}'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onMeasurementTap,
                  child: InfoCard('Kilo', '${client.weight} kg'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onMeasurementTap,
                  child: InfoCard('Boy', '${client.height} cm'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Container(
          height: 200,
          padding: EdgeInsets.all(16),
          child: BMIChartWidget(clientId: client.uid),
        ),
      ],
    );
  }
}
