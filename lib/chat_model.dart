class ChatModel {
  String _title = '';
  int _id = 0;

  ChatModel(String title, int id) {
    _title = title;
    _id = id;
  }

  ChatModel.fromJson(Map<String, dynamic> json)
      : _id = (json['id'] as num).toInt(),
        _title = (json['title'] as String?)?.isNotEmpty == true
            ? json['title'] as String
            : 'Chat #${(json['id'] as num).toInt()}';

  get title => _title;

  set title(value) => _title = value ?? 'Chat sem título';

  get id => _id;

  set id(value) => _id = value;
}