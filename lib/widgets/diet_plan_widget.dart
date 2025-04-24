import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/diet_plan.dart';
import '../services/diet_plan_service.dart';
import '../services/pdf_service.dart';
import '../utils/constants.dart';
import 'pdf_options_menu.dart';

class DietPlanWidget extends StatefulWidget {
  final String clientId;
  final bool isProfileView;
  final DietPlanService _dietPlanService = DietPlanService();
  final PdfService _pdfService = PdfService();

  DietPlanWidget({
    Key? key,
    required this.clientId,
    this.isProfileView = false,
  }) : super(key: key);

  @override
  State<DietPlanWidget> createState() => _DietPlanWidgetState();
}

class _DietPlanWidgetState extends State<DietPlanWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Center(
            child: Text(
              'Diyet Planlarım',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.color1,
              ),
            ),
          ),
        ),
        FutureBuilder<List<DietPlan>>(
          future:
              widget._dietPlanService.getDietPlansForClient(widget.clientId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Bir hata oluştu'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Diyet planı bulunamadı'));
            }

            final dietPlans = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: dietPlans.length,
              itemBuilder: (context, index) {
                final plan = dietPlans[index];
                return _buildDietPlanCard(context, plan);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDietPlanCard(BuildContext context, DietPlan dietPlan) {
    final createdAt = dietPlan.createdAt.toDate();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dietPlan.title.isEmpty
                                    ? 'Diyet Listesi'
                                    : dietPlan.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                DateFormat('dd.MM.yyyy').format(createdAt),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    PdfOptionsMenu(
                      dietPlan: dietPlan,
                      pdfService: widget._pdfService,
                    ),
                  ],
                ),
                if (_isExpanded)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMealSection('Kahvaltı', dietPlan.breakfast,
                            dietPlan.breakfastTime),
                        Divider(height: 24),
                        _buildMealSection(
                            'Öğle Yemeği', dietPlan.lunch, dietPlan.lunchTime),
                        Divider(height: 24),
                        _buildMealSection(
                            'Ara Öğün', dietPlan.snack, dietPlan.snackTime),
                        Divider(height: 24),
                        _buildMealSection('Akşam Yemeği', dietPlan.dinner,
                            dietPlan.dinnerTime),
                        if (dietPlan.notes.isNotEmpty) ...[
                          Divider(height: 24),
                          Text(
                            'Notlar:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            dietPlan.notes,
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMealSection(String title, String content, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(color: Colors.black87),
        ),
      ],
    );
  }
}
