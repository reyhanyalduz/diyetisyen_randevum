import 'package:flutter/material.dart';

class TagSection extends StatefulWidget {
  final BuildContext context;
  final String title;
  final List<String> initialTags;
  final Function(List<String>) onTagsUpdated;

  const TagSection({
    required this.context,
    required this.title,
    required this.initialTags,
    required this.onTagsUpdated,
  });

  @override
  _TagSectionState createState() => _TagSectionState();
}

class _TagSectionState extends State<TagSection> {
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.title} Ekle'),
        content: TextField(
          controller: _tagController,
          decoration: InputDecoration(
            hintText: 'Yeni ${widget.title.toLowerCase()} girin',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (_tagController.text.isNotEmpty) {
                setState(() {
                  _tags.add(_tagController.text);
                  widget.onTagsUpdated(_tags);
                });
                _tagController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
      widget.onTagsUpdated(_tags);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _addTag,
            ),
          ],
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _tags.asMap().entries.map((entry) {
            return Chip(
              label: Text(entry.value),
              onDeleted: () => _removeTag(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}
