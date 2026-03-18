import 'dart:ffi';

class ChatModel {
  String _title = '';
  int _id = 0;



  ChatModel (String title, int id){
    if (title == null){
      title = "null";
    }
    this._title = title;
    this._id = _id;
  }

    ChatModel.fromJson(Map<String, dynamic> json)
    : this._title = json['title'] as String,
     this._id = json['id'] as int;
  
  get title => this._title;

 set title( value){
  if (value == null){
    value = "null";
  }
  this._title = value;
  }


 get id => this._id;

 set id(value) => this._id = value;


}