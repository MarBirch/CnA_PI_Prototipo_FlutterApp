class LoginUser {
  String _username = '';
  String _password = '';

  LoginUser(String username, String password){
    this._username = username;
    this._password = password;
  }

   LoginUser.fromJson(Map<String,dynamic> json)
  //   :_id = json['id'],
      :_username = json['username'],
      _password = json['password']
  //    _weight = json['weight'],
  //    _height = json['height']
      ;
  
  static Map<String, dynamic> toJson(LoginUser loginUser) =>
      {'username': loginUser.username, 'password': loginUser.password};
    
  get username => this._username;

 set username( value) => this._username = value;

  get password => this._password;

 set password( value) => this._password = value;
}