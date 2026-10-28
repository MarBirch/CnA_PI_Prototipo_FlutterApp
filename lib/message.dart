class ChatMessage {
  String _message = '';
  String _role = '';
  bool _isUser = false;

  ChatMessage (String message, String role, bool isUser){
    this._message = message;
    this._role = role;
    this._isUser = isUser;
  }

  ChatMessage.fromJson(Map<String, dynamic> json)
    : this._message = json['content'] as String,
     this._role = json['role'] as String;
  
  get message => this._message;

 set message( value) => this._message = value;

   get role => this._role;

 set role( value) => this._role = value;


 get isUser => this._isUser;

 set isUser(value) => this._isUser = value;


}