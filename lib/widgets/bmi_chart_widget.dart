import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/constants.dart';

class BMIChartWidget extends StatelessWidget {
  final String clientId;

  const BMIChartWidget({Key? key, required this.clientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bmi_history')
            .where('clientId', isEqualTo: clientId)
            .orderBy('date', descending: false)
            //.limit(10)
            .snapshots(),
        builder: (context, bmiSnapshot) {
          if (bmiSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bmiSnapshot.hasError) {
            debugPrint("BMI veri hatası: ${bmiSnapshot.error}");
            return const Center(child: Text('Veri alınırken hata oluştu'));
          }

          if (!bmiSnapshot.hasData ||
              bmiSnapshot.data == null ||
              bmiSnapshot.data!.docs.isEmpty) {
            debugPrint("BMI verisi bulunamadı");
            return const Center(
                child: Text('Henüz VKİ geçmişi bulunmamaktadır'));
          }

          final bmiData = bmiSnapshot.data!.docs;
          debugPrint("BMI veri sayısı: ${bmiData.length}");

          // Haftalık son değerleri grupla
          final Map<String, Map<String, dynamic>> weeklyData = {};
          for (var doc in bmiData) {
            final data = doc.data() as Map<String, dynamic>;
            final Timestamp timestamp = data['date'];
            final DateTime date = timestamp.toDate();

            // O haftanın pazar gününü bul
            final DateTime sunday = date
                .subtract(Duration(days: date.weekday))
                .add(const Duration(days: 7));
            final String weekKey = DateFormat('yyyy-MM-dd').format(sunday);

            // Her hafta için son değeri sakla
            weeklyData[weekKey] = data;
            debugPrint(
                "BMI verisi eklendi: Tarih: $weekKey, BMI: ${data['bmi']}");
          }

          // Haftalık verileri tarihe göre sırala ve spots oluştur
          final sortedWeeks = weeklyData.keys.toList()..sort();
          final spots = sortedWeeks.asMap().entries.map((entry) {
            final data = weeklyData[entry.value];
            final bmiValue = data != null && data['bmi'] != null
                ? (data['bmi'] as num).toDouble()
                : 0.0;
            return FlSpot(entry.key.toDouble(), bmiValue);
          }).toList();

          if (spots.isEmpty) {
            debugPrint("BMI spot verisi oluşturulamadı");
            return const Center(
                child: Text('Henüz VKİ geçmişi bulunmamaktadır'));
          }

          debugPrint("Toplam BMI spot sayısı: ${spots.length}");

          // BMI değerleri için aralık belirle
          final minBmi = 10.0;
          final maxBmi = 50.0;

          // En son BMI değerini al
          final lastBmi = spots.isNotEmpty ? spots.last.y : 0.0;

          return Stack(
            children: [
              LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  backgroundColor: Colors.white,
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      // Alt sınır çizgisi (18.5)
                      HorizontalLine(
                        y: 18.5,
                        color: Colors.green.withOpacity(0.3),
                        strokeWidth: 1,
                      ),
                      // Üst sınır çizgisi (24.9)
                      HorizontalLine(
                        y: 24.9,
                        color: Colors.green.withOpacity(0.3),
                        strokeWidth: 1,
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        reservedSize: 40,
                        interval: 0.1,
                        getTitlesWidget: (value, meta) {
                          return const Text('');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble())
                            return const Text('');
                          if (value.toInt() >= sortedWeeks.length)
                            return const Text('');

                          // Calculate interval to show max 6 labels
                          final interval = (sortedWeeks.length / 6).ceil();
                          if (value.toInt() % interval != 0)
                            return const Text('');

                          final dateStr = sortedWeeks[value.toInt()];
                          return Text(
                            DateFormat('MM').format(DateTime.parse(dateStr)),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        interval: 1,
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: spots.isNotEmpty ? spots.length - 1 : 0,
                  minY: minBmi,
                  maxY: maxBmi,
                  lineBarsData: [
                    // Normal BMI aralığını gösteren alan
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 18.5),
                        FlSpot(spots.isNotEmpty ? spots.length - 1 : 0, 18.5),
                      ],
                      isCurved: false,
                      color: Colors.transparent,
                      barWidth: 0,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                        cutOffY: 24.9,
                        applyCutOffY: true,
                      ),
                    ),
                    // Asıl BMI çizgisi
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.color1,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
              // Son BMI değerini sağ üst köşede göster
              Positioned(
                top: 10,
                right: 25,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.color1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'VKİ: ${lastBmi.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.color1,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
