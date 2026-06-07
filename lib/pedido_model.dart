import 'dart:ffi';

import 'package:big_decimal/big_decimal.dart';

class PedidoModel {
  late DateTime _dataCriada;
  late DateTime _dataPedido;
  late int _id;
  late List<dynamic> _ingredientes;
  late String _nomeMarmiteria;
  late String _status;
  late double _valor;
  get dataCriada => this._dataCriada;

 set dataCriada( value) => this._dataCriada = value;

  get dataPedido => this._dataPedido;

 set dataPedido( value) => this._dataPedido = value;

  get id => this._id;

 set id( value) => this._id = value;

  get ingredientes => this._ingredientes;

 set ingredientes( value) => this._ingredientes = value;

  get nomeMarmiteria => this._nomeMarmiteria;

 set nomeMarmiteria( value) => this._nomeMarmiteria = value;

  get status => this._status;

 set status( value) => this._status = value;

  get valor => this._valor;

 set valor( value) => this._valor = value;
  
  PedidoModel(DateTime dataCriada, DateTime dataPedido, int id, List<dynamic> ingredientes, String nomeMarmiteria, String status, double valor){
    this._dataCriada = dataCriada;
    this._dataPedido = dataPedido;
    this._id = id;
    this._ingredientes = ingredientes;
    this._nomeMarmiteria = nomeMarmiteria;
    this._status = status;
    this._valor = valor;
  }

    PedidoModel.fromJson(Map<String, dynamic> json)
    :this._dataCriada = DateTime.parse(json['dataCriada']),
    // this._dataPedido = DateTime.parse(json['dataPedido']),
    this._id = json['id'] ?? 0,
    this._ingredientes = json['ingredientes'] as List<dynamic>? ?? [],
    this._nomeMarmiteria = json['nomeMarmiteria'] as String? ?? '',
    this._status = json['status'] as String? ?? 'DESCONHECIDO',
    this._valor = (json['valor'] as num?)?.toDouble() ?? 0.0;
  


}