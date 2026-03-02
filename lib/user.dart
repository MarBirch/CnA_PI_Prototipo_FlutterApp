class User {
  String _username = '';
  String _password = '';
  String _token = '';

  User();

  User.fromJson(Map<String, dynamic> json)
    : _username = json['username'],
      _password = json['password'];

  get username => this._username;

  set username(value) => this._username = value;

  get password => this._password;

  set password(value) => this._password = value;

  get token => this._token;

  set token(value) => this._token = value;
}
