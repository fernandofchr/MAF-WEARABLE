import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'mqtt_service.dart';

void main() {
  runApp(const MyApp());
}

/// [MyApp] es la clase principal de la aplicación Flutter. 
/// Inicia la aplicación con un tema oscuro y establece [GaugeScreen] como la pantalla principal.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gauge MQTT App',
      theme: ThemeData(
        brightness: Brightness.dark, // Configura el tema oscuro de la aplicación
        scaffoldBackgroundColor: Colors.black, // Establece un fondo negro para todas las pantallas
      ),
      debugShowCheckedModeBanner: false, // Oculta el banner de "debug" en la aplicación
      home: const GaugeScreen(), // Define la pantalla principal de la aplicación
    );
  }
}

/// [GaugeScreen] es un widget con estado que muestra un conjunto de gauges en diferentes pestañas.
/// Los valores de los gauges se actualizan en tiempo real desde un servidor MQTT.
class GaugeScreen extends StatefulWidget {
  const GaugeScreen({super.key});

  @override
  _GaugeScreenState createState() => _GaugeScreenState();
}

class _GaugeScreenState extends State<GaugeScreen> {
  late MqttService _mqttService; // Servicio MQTT para conectar y recibir datos
  double _temperature = 12.4; // Valor inicial para la temperatura (RPM)
  double _humidity = 5.0; // Valor inicial para la humedad (LDR)
  double _pressure = 5.0; // Valor inicial para la presión (UV)

  @override
  void initState() {
    super.initState();
    connectMqtt(); // Conectar al servidor MQTT cuando el widget se inicia
  }

  /// Método para conectar al servidor MQTT y suscribirse a los tópicos de interés.
  void connectMqtt() async {
    _mqttService = MqttService('broker.hivemq.com', 'texto123o'); // Inicializa el servicio MQTT
    await _mqttService.connect(); // Conecta al broker MQTT

    // Escucha el tópico 'topico/rpm' y actualiza el valor de _temperature.
    _mqttService.getValueStream('topico/rpm').listen((temperature) {
      setState(() {
        _temperature = temperature;
      });
    });

    // Escucha el tópico 'topico/ldr_value' y actualiza el valor de _humidity.
    _mqttService.getValueStream('topico/ldr_value').listen((humidity) {
      setState(() {
        _humidity = humidity;
      });
    });

    // Escucha el tópico 'topico/uv' y actualiza el valor de _pressure.
    _mqttService.getValueStream('topico/uv').listen((pressure) {
      setState(() {
        _pressure = pressure;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Número de pestañas en el TabBar
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MAF - WATCH'), // Título en la barra superior
          centerTitle: true, // Centrar el título en la barra superior
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: "RPM"), // Pestaña para RPM
              Tab(icon: Icon(Icons.wb_sunny), text: "UV"), // Pestaña para UV
              Tab(icon: Icon(Icons.lightbulb), text: "LDR"), // Pestaña para LDR
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GaugeTab(
              title: 'BPM',
              min: 0,
              max: 200,
              value: _temperature, // Valor actual de la temperatura (RPM)
              ranges: [
                GaugeRange(startValue: 0, endValue: 50, color: Colors.blue),
                GaugeRange(startValue: 50, endValue: 150, color: Colors.green),
                GaugeRange(startValue: 150, endValue: 200, color: Colors.red),
              ],
            ),
            GaugeTab(
              title: 'UV',
              min: 0,
              max: 100,
              value: _pressure, // Valor actual de la presión (UV)
              ranges: [
                GaugeRange(startValue: 0, endValue: 30, color: Colors.blue),
                GaugeRange(startValue: 30, endValue: 60, color: Colors.green),
                GaugeRange(startValue: 60, endValue: 100, color: Colors.red),
              ],
            ),
            GaugeTab(
              title: 'LDR',
              min: 0,
              max: 100,
              value: _humidity, // Valor actual de la humedad (LDR)
              ranges: [
                GaugeRange(startValue: 0, endValue: 30, color: Colors.blue),
                GaugeRange(startValue: 30, endValue: 60, color: Colors.green),
                GaugeRange(startValue: 60, endValue: 100, color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// [GaugeTab] es un widget que representa un gauge individual en la pantalla.
/// Muestra un gauge radial con un valor y un título, utilizando los datos pasados a través de los parámetros.
class GaugeTab extends StatelessWidget {
  final String title; // Título del gauge (por ejemplo, "RPM", "UV", "LDR")
  final double min; // Valor mínimo del gauge
  final double max; // Valor máximo del gauge
  final double value; // Valor actual que se muestra en el gauge
  final List<GaugeRange> ranges; // Rango de colores para las distintas zonas del gauge

  const GaugeTab({
    required this.title,
    required this.min,
    required this.max,
    required this.value, 
    required this.ranges,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), // Estilo del texto
          ),
          SizedBox(
            height: 200,
            child: SfRadialGauge(
              backgroundColor: Colors.black, // Fondo negro para el gauge
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: min,
                  maximum: max,
                  ranges: ranges,
                  pointers: <GaugePointer>[
                    NeedlePointer(value: value), // Muestra el valor actual con una aguja
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Text(
                        '$value', // Muestra el valor numérico dentro del gauge
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      angle: 90,
                      positionFactor: 0.5, // Posición del valor dentro del gauge
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
