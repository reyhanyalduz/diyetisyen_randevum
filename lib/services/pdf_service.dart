import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/diet_plan.dart';

class PdfService {
  Future<void> generateDietPlanPdf(DietPlan dietPlan) async {
    final pdf = pw.Document();

    final createdAt = dietPlan.createdAt.toDate();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: pw.Font.ttf(
                await rootBundle.load("assets/fonts/OpenSans-Regular.ttf")),
            bold: pw.Font.ttf(
                await rootBundle.load("assets/fonts/OpenSans-Bold.ttf")),
          ),
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              dietPlan.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Tarih: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          _buildMealSection(
              'Kahvaltı', dietPlan.breakfast, dietPlan.breakfastTime),
          pw.SizedBox(height: 15),
          _buildMealSection('Öğle Yemeği', dietPlan.lunch, dietPlan.lunchTime),
          pw.SizedBox(height: 15),
          _buildMealSection('Ara Öğün', dietPlan.snack, dietPlan.snackTime),
          pw.SizedBox(height: 15),
          _buildMealSection(
              'Akşam Yemeği', dietPlan.dinner, dietPlan.dinnerTime),
          if (dietPlan.notes.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Notlar:',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              dietPlan.notes,
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );

    // PDF'i kaydet ve aç
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/diyet_plani.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  pw.Widget _buildMealSection(String title, String content, String time) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Saat: $time',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            content,
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
