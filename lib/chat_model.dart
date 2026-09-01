import 'package:flutter/foundation.dart';

class ChatModel {
  String _title = '';
  int _id = 0;

  ChatModel(String title, int id) {
    _title = title;
    _id = id;
  }

  ChatModel.fromJson(Map<String, dynamic> json) {
    // Aceita id como int ou num
    _id = (json['id'] as num?)?.toInt() ?? 0;

    // Aceita title como string ou nulo
    final rawTitle = json['title'];
    if (rawTitle != null && rawTitle.toString().trim().isNotEmpty) {
      _title = rawTitle.toString().trim();
    } else {
      _title = 'Conversa Nutri #$_id';
    }

    debugPrint('[ChatModel] id=$_id  title=$_title  raw=$json');
  }

  get title => _title;

  set title(value) => _title = value ?? 'Conversa Nutri';

  get id => _id;

  set id(value) => _id = value;
}