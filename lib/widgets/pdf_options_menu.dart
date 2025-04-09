import 'package:flutter/material.dart';

import '../models/diet_plan.dart';
import '../services/pdf_service.dart';

class PdfOptionsMenu extends StatelessWidget {
  final DietPlan dietPlan;
  final PdfService pdfService;

  const PdfOptionsMenu({
    Key? key,
    required this.dietPlan,
    required this.pdfService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'large') {
          await pdfService.generateDietPlanPdf(
            dietPlan,
            titleSize: 28.0,
            subtitleSize: 20.0,
            textSize: 18.0,
          );
        } else if (value == 'default') {
          await pdfService.generateDietPlanPdf(dietPlan);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'default',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf),
              SizedBox(width: 8),
              Text('Varsayılan Boyutta PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'large',
          child: Row(
            children: [
              Icon(Icons.text_fields),
              SizedBox(width: 8),
              Text('Büyük Yazılı PDF'),
            ],
          ),
        ),
      ],
    );
  }
}
