import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/diet_plan.dart';

class DietPlanDialog extends StatefulWidget {
  final String clientId;
  final String dietitianId;
  final DietPlan? existingPlan;

  const DietPlanDialog({
    Key? key,
    required this.clientId,
    required this.dietitianId,
    this.existingPlan,
  }) : super(key: key);

  @override
  _DietPlanDialogState createState() => _DietPlanDialogState();
}

class _DietPlanDialogState extends State<DietPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _snackController = TextEditingController();
  final _dinnerController = TextEditingController();
  final _breakfastTimeController = TextEditingController();
  final _lunchTimeController = TextEditingController();
  final _snackTimeController = TextEditingController();
  final _dinnerTimeController = TextEditingController();
  final _notesController = TextEditingController();

  TimeOfDay? _breakfastTime;
  TimeOfDay? _lunchTime;
  TimeOfDay? _snackTime;
  TimeOfDay? _dinnerTime;

  @override
  void initState() {
    super.initState();
    if (widget.existingPlan != null) {
      _titleController.text = widget.existingPlan!.title;
      _breakfastController.text = widget.existingPlan!.breakfast;
      _lunchController.text = widget.existingPlan!.lunch;
      _snackController.text = widget.existingPlan!.snack;
      _dinnerController.text = widget.existingPlan!.dinner;
      _breakfastTimeController.text = widget.existingPlan!.breakfastTime;
      _lunchTimeController.text = widget.existingPlan!.lunchTime;
      _snackTimeController.text = widget.existingPlan!.snackTime;
      _dinnerTimeController.text = widget.existingPlan!.dinnerTime;
      _notesController.text = widget.existingPlan!.notes;
    } else {
      // Varsayılan saatleri ayarla
      _breakfastTimeController.text = '08:00';
      _lunchTimeController.text = '12:00';
      _snackTimeController.text = '15:00';
      _dinnerTimeController.text = '18:00';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _breakfastController.dispose();
    _lunchController.dispose();
    _snackController.dispose();
    _dinnerController.dispose();
    _breakfastTimeController.dispose();
    _lunchTimeController.dispose();
    _snackTimeController.dispose();
    _dinnerTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context,
      TextEditingController controller, String label) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingPlan == null
          ? 'Yeni Diyet Listesi'
          : 'Diyet Listesini Düzenle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Diyet Listesi Başlığı',
                  hintText: 'Örn: Kilo Verme Diyeti, Protein Diyeti vb.',
                ),
              ),
              SizedBox(height: 16),
              _buildMealInput(
                  'Kahvaltı', _breakfastController, _breakfastTimeController),
              _buildMealInput(
                  'Öğle Yemeği', _lunchController, _lunchTimeController),
              _buildMealInput(
                  'Ara Öğün', _snackController, _snackTimeController),
              _buildMealInput(
                  'Akşam Yemeği', _dinnerController, _dinnerTimeController),
              SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notlar',
                  hintText: 'Ek bilgiler, öneriler...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final dietPlan = DietPlan(
                id: widget.existingPlan?.id,
                clientId: widget.clientId,
                dietitianId: widget.dietitianId,
                title: _titleController.text,
                breakfast: _breakfastController.text,
                lunch: _lunchController.text,
                snack: _snackController.text,
                dinner: _dinnerController.text,
                breakfastTime: _breakfastTimeController.text,
                lunchTime: _lunchTimeController.text,
                snackTime: _snackTimeController.text,
                dinnerTime: _dinnerTimeController.text,
                notes: _notesController.text,
                createdAt: widget.existingPlan?.createdAt ?? Timestamp.now(),
              );
              Navigator.pop(context, dietPlan);
            }
          },
          child: Text('Kaydet'),
        ),
      ],
    );
  }

  Widget _buildMealInput(String label, TextEditingController mealController,
      TextEditingController timeController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        TextFormField(
          controller: mealController,
          decoration: InputDecoration(
            hintText: 'Yemek içeriği...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen $label içeriğini girin';
            }
            return null;
          },
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Saat',
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () => _selectTime(context, timeController, label),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen saat seçin';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
