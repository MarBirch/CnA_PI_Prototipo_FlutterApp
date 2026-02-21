class ChatMessage {
  String _message = '';
  bool _isUser = false;

  ChatMessage (String message, bool isUser){
    this._message = message;
    this._isUser = isUser;
  }
  
  get message => this._message;

 set message( value) => this._message = value;


 get isUser => this._isUser;

 set isUser(value) => this._isUser = value;


}