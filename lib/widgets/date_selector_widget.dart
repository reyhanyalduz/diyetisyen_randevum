import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class DateSelector extends StatefulWidget {

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  const DateSelector( {
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  DateTime selectedDate= DateTime.now();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(7, (index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          bool isSelected = widget.selectedDate.day == date.day &&
              widget.selectedDate.month == date.month &&
              widget.selectedDate.year == date.year;
          return GestureDetector(
            onTap: () {
              widget.onDateSelected(date);// Trigger callback with the selected date
            },
            child: Container(
              width: 50,
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.color3 : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E', 'tr').format(date)),
                  Text("${date.day}"),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}


