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
        SizedBox(height: 8),
        _tags.isEmpty
            ? Text('Henüz ${widget.title.toLowerCase()} eklenmemiş',
                style: TextStyle(color: Colors.grey))
            : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _tags.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tags[index],
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20),
                          onPressed: () => _removeTag(index),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
