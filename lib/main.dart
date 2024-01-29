import 'dart:async';

import 'package:caidas/services/caida_services.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


void main() async{
  
  //este metodo se asegura de ejecutar todas las inicializaciones antes de acceder a la interfaz
  WidgetsFlutterBinding.ensureInitialized();
  //inicializamos las notificaciones
  await initNotifications();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PaginaPrincipal(),
    );
  }
}

class PaginaPrincipal extends StatefulWidget {
  @override
  _MiPaginaPrincipalState createState() => _MiPaginaPrincipalState();
}

class _MiPaginaPrincipalState extends State<PaginaPrincipal> {
  //Para controlar los diferentes sensores podemos usar unos buffers para almacenar los datos de los sensores
  // fijaremos un tamaño de 100 datos para cada buffer
  final int bufferSize = 100;

  //Buffer para almacenar los datos del giroscopio
  List<Map<String,dynamic>> gyroscopeBuffer = [];
  //Buffer para almacenar los datos del acelerometro
  List<Map<String,dynamic>> accelerationBuffer = [];

  //Variables para almacenar los datos del giroscopio
  GyroscopeEvent? _eventoGiroscopio;
  //Variables para almacenar los datos del acelerometro
  AccelerometerEvent? _accelerometerEvent;

  bool hayCaida = false;
  
  //Lista para almacenar los datos de las multiples suscripciones a los sensores
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];


  

  

  @override
  void initState() {
    super.initState();
    
    //Añadimos las suscripciones a los sensores
    _streamSubscriptions.add(
      gyroscopeEventStream(
        //frecuencia de muestreo de 100ms
        samplingPeriod: Duration(milliseconds: 100)
        ).listen((GyroscopeEvent event) {
      
      //Cada vez que se recibe un dato del giroscopio se añade al buffer, 
      //si el buffer supera el tamaño maximo se elimina el primer dato
      setState(() {
        _eventoGiroscopio = event;
        gyroscopeBuffer.add(
          {
            "x": event.x,
            "y": event.y,
            "z": event.z,
          });
          if(gyroscopeBuffer.length > bufferSize){
            gyroscopeBuffer.removeAt(0);
          }

      });
    },
    
    ));
    _streamSubscriptions.add(
      accelerometerEventStream(samplingPeriod: Duration(milliseconds: 100)).listen(
        (AccelerometerEvent event) {
          setState(() {
            _accelerometerEvent = event;
            //una caida se produciría cuando el valor de la aceleración en el eje z supera el valor de 10
            accelerationBuffer.add(
              {
                "x": event.x,
                "y": event.y,
                "z": event.z,
              });
            //si el buffer supera el tamaño maximo se elimina el primer dato
            if(accelerationBuffer.length > bufferSize){
              accelerationBuffer.removeAt(0);
            }
            //si el valor de la aceleración en el eje z supera el valor de 10 se muestra una notificación
            if(event.z > 10){
              mostrarNotification("Emergencia", "Se ha detectado una caida");
              hayCaida = true;
            }
          }); 
        },
        
      ),
    );
    
  }

  @override
  void dispose() {
      super.dispose();
      for (final subscription in _streamSubscriptions) {
        subscription.cancel();
      }
  }

  // Resto del código del widget, incluyendo UI, funciones de detección, etc.

  @override
  Widget build(BuildContext context) {
    // Construye la interfaz de usuario de la aplicación
    // Aquí puedes agregar botones u otros elementos para interactuar con la detección de caídas.
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor de caídas'),
      ),
      body:Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    4: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      children: [
                        Text('Giroscopio:'),
                        Text('X: ${_eventoGiroscopio?.x ?? 0}'),
                        Text('Y: ${_eventoGiroscopio?.y ?? 0}'),
                        Text('Z: ${_eventoGiroscopio?.z ?? 0}'),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Accelerometer'),
                        ),
                        Text(_accelerometerEvent?.x.toStringAsFixed(1) ?? '?'),
                        Text(_accelerometerEvent?.y.toStringAsFixed(1) ?? '?'),
                        Text(_accelerometerEvent?.z.toStringAsFixed(1) ?? '?'),
                      ],
                    ),
                    
                  ],
                  
                ), //Si hay caida mostramos el boton para llamar a emergencias
                (hayCaida) ? ElevatedButton(
                  onPressed: ()async {await llamaEmergencias();}, //Asignamos la funcion llamaEmergencias al boton
                  style: ElevatedButton.styleFrom(
                          primary: Colors.red,
                          onPrimary: Colors.white,
                          onSurface: Colors.grey,
                  ),
                  child: Text(
                            'Avisar a Emergencias',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                  ),))  : Text('No hay caida'),
              ],
            ),
          ),
    );
  }

}