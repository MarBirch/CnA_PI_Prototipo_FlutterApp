import 'package:prototipo1/user.dart';

class UserRepository {
  List<User> _userList = [];

  UserRepository();

  List<User> get users => this._userList;
  set users(List<User> value) => this._userList = value;
}
