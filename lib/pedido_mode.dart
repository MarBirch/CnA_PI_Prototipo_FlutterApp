import 'dart:ffi';

class PedidoModel {
  String _user = '';
  int _id = 0;



  PedidoModel (String user, int id){
    if (user == null){
      user = "null";
    }
    this._user = user;
    this._id = _id;
  }

    PedidoModel.fromJson(Map<String, dynamic> json)
    : this._user = json['valor']?.toString() ?? '',
     this._id = json['id'] as int;
  
  get user => this._user;

 set user( value){
  if (value == null){
    value = "null";
  }
  this._user = value;
  }


 get id => this._id;

 set id(value) => this._id = value;


}