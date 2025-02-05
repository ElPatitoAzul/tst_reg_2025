import 'dart:io';

import 'package:flutter/material.dart';

class DatosEnviadosPage extends StatefulWidget {
  final String datosEnviados;
  final String rutaArchivo;

  DatosEnviadosPage({required this.datosEnviados, required this.rutaArchivo});

  @override
  _DatosEnviadosPageState createState() => _DatosEnviadosPageState();
}

class _DatosEnviadosPageState extends State<DatosEnviadosPage> {
  late String _contenidoArchivo;

  @override
  void initState() {
    super.initState();
    _leerArchivo();
  }

  Future<void> _leerArchivo() async {
    try {
      final archivo = File(widget.rutaArchivo);
      final contenido = await archivo.readAsString();
      setState(() {
        _contenidoArchivo = contenido;
      });
    } catch (e) {
      print('Error al leer el archivo: $e');
      setState(() {
        _contenidoArchivo = 'Error al leer el archivo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Datos Enviados'),
        backgroundColor: Colors.blue, // Cambiar el color de fondo de la AppBar
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos Enviados:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              widget.datosEnviados,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Contenido del Archivo:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _contenidoArchivo ?? '',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
     
    );
  }
}
