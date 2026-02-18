class User {
  int _id =0;
  String _username = '';
  String _password = '';
  double _weight = 0;
  double _height = 0;

  User();

  User.fromJson(Map<String,dynamic> json)
    :_id = json['id'],
     _username = json['username'],
     _password = json['password'],
     _weight = json['weight'],
     _height = json['height']
     ;
  
  
 int get id => this._id;

 set id(int value) => this._id = value;

  get username => this._username;

 set username( value) => this._username = value;

  get password => this._password;

 set password( value) => this._password = value;

  get weight => this._weight;

 set weight( value) => this._weight = value;

  get height => this._height;

 set height( value) => this._height = value;
}