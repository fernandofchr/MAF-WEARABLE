import 'package:flutter/material.dart'; // Importa los componentes esenciales de Flutter.
import 'package:syncfusion_flutter_gauges/gauges.dart'; // Importa la biblioteca de Syncfusion para crear gauges.
import 'mqtt_service.dart'; // Importa el servicio MQTT personalizado para manejar la conexión y la transmisión de datos.

void main() {
  runApp(const MyApp()); // La función principal que ejecuta la aplicación.
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gauge MQTT App', // Establece el título de la aplicación.
      theme: ThemeData(
        brightness: Brightness.dark, // Define el tema oscuro para la aplicación.
        scaffoldBackgroundColor: Colors.black, // Establece el fondo de la aplicación en negro.
      ),
      debugShowCheckedModeBanner: false, // Oculta el banner de depuración.
      home: const GaugeScreen(), // Define la pantalla principal de la aplicación.
    );
  }
}

class GaugeScreen extends StatefulWidget {
  const GaugeScreen({super.key});

  @override
  _GaugeScreenState createState() => _GaugeScreenState(); // Crea el estado asociado a la pantalla principal.
}

class _GaugeScreenState extends State<GaugeScreen> {
  late MqttService _mqttService; // Declaración del servicio MQTT.
  double _temperature = 12.4; // Valor inicial para la temperatura.
  double _humidity = 5.0; // Valor inicial para la humedad.
  double _pressure = 5.0; // Valor inicial para la presión.

  @override
  void initState() {
    super.initState();
    connectMqtt(); // Conecta el servicio MQTT cuando se inicializa el estado.
  }

  // Método para conectar el servicio MQTT y suscribirse a los tópicos.
  void connectMqtt() async {
    _mqttService = MqttService('broker.hivemq.com', 'texto123o'); // Conecta al broker MQTT.
    await _mqttService.connect(); // Espera a que la conexión se establezca.

    // Escucha los mensajes del tópico 'topico/rpmMejorado' y actualiza la temperatura.
    _mqttService.getValueStream('topico/rpmMejorado').listen((temperature) {
      setState(() {
        _temperature = temperature;
      });
    });

    // Escucha los mensajes del tópico 'topico/ldr_value' y actualiza la humedad.
    _mqttService.getValueStream('topico/ldr_value').listen((humidity) {
      setState(() {
        _humidity = humidity;
      });
    });

    // Escucha los mensajes del tópico 'topico/uv' y actualiza la presión.
    _mqttService.getValueStream('topico/uv').listen((pressure) {
      setState(() {
        _pressure = pressure;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Define el número de pestañas.
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MAF - WATCH'), // Título de la barra de la aplicación.
          centerTitle: true, // Centra el título.
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: "RPM"), // Pestaña para el gauge de RPM.
              Tab(icon: Icon(Icons.wb_sunny), text: "UV"), // Pestaña para el gauge de UV.
              Tab(icon: Icon(Icons.lightbulb), text: "LDR"), // Pestaña para el gauge de LDR.
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GaugeTab(
              title: 'RPM', // Título del gauge de RPM.
              min: 0, // Valor mínimo del gauge.
              max: 200, // Valor máximo del gauge.
              value: _temperature, // Valor actual del gauge.
              ranges: [
                GaugeRange(startValue: 0, endValue: 50, color: Colors.blue), // Rango de color azul.
                GaugeRange(startValue: 50, endValue: 150, color: Colors.green), // Rango de color verde.
                GaugeRange(startValue: 150, endValue: 200, color: Colors.red), // Rango de color rojo.
              ],
              footer: "Promedio de RPM", // Texto que aparece debajo del gauge.
            ),
            GaugeTab(
              title: 'UV', // Título del gauge de UV.
              min: 0,
              max: 100,
              value: _pressure,
              ranges: [
                GaugeRange(startValue: 0, endValue: 30, color: Colors.blue),
                GaugeRange(startValue: 30, endValue: 60, color: Colors.green),
                GaugeRange(startValue: 60, endValue: 100, color: Colors.red),
              ],
            ),
            GaugeTab(
              title: 'LDR', // Título del gauge de LDR.
              min: 0,
              max: 100,
              value: _humidity,
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

class GaugeTab extends StatelessWidget {
  final String title; // Título del gauge.
  final double min; // Valor mínimo del gauge.
  final double max; // Valor máximo del gauge.
  final double value; // Valor actual del gauge.
  final List<GaugeRange> ranges; // Rango de colores del gauge.
  final String? footer; // Texto opcional para mostrar debajo del gauge.

  const GaugeTab({
    required this.title,
    required this.min,
    required this.max,
    required this.value,
    required this.ranges,
    this.footer, // Constructor con el parámetro footer.
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(
            height: 200,
            child: SfRadialGauge(
              backgroundColor: Colors.black, // Color de fondo del gauge.
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: min,
                  maximum: max,
                  ranges: ranges,
                  pointers: <GaugePointer>[
                    NeedlePointer(value: value), // Indicador de aguja.
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Text(
                        '$value', // Valor que se muestra en el gauge.
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      angle: 90,
                      positionFactor: 0.5,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (footer != null) // Si el footer no es nulo, se muestra el texto debajo del gauge.
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                footer!,
                style: const TextStyle(
                    fontSize: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
