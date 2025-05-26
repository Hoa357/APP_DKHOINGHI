import 'package:flutter/material.dart';

class SuccessMessage extends StatelessWidget {
  final String message;

  const SuccessMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[800], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.green[800])),
          ),
        ],
      ),
    );
  }
}
