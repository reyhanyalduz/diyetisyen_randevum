import 'package:flutter/material.dart';

import '../models/user.dart';
import 'tag_section_widget.dart';

class ProfessionalInfoWidget extends StatelessWidget {
  final Dietitian dietitian;
  final VoidCallback onEdit;
  final Function(List<String>) onExpertiseUpdated;

  const ProfessionalInfoWidget({
    Key? key,
    required this.dietitian,
    required this.onEdit,
    required this.onExpertiseUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 14, top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hakkımda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: onEdit,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (dietitian.about.isNotEmpty) ...[
                  Text(
                    dietitian.about,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                if (dietitian.experience.isNotEmpty) ...[
                  Text(
                    'Deneyim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    dietitian.experience,
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 16),
                ],
                if (dietitian.education.isNotEmpty) ...[
                  Text(
                    'Eğitim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    dietitian.education,
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: TagSection(
            padding: EdgeInsets.only(left: 6, top: 6, bottom: 8),
            context: context,
            title: 'Uzmanlık Alanları',
            initialTags: dietitian.expertiseAreas,
            onTagsUpdated: onExpertiseUpdated,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
