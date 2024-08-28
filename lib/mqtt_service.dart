 // Importa los componentes esenciales de Flutter para la conexión mqtt
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// `MqttService` es una clase que maneja la conexión y la suscripción
/// a un broker MQTT utilizando el cliente `mqtt_client`.
class MqttService {
  // Cliente MQTT que maneja la conexión al broker
  final MqttServerClient client;

  /// Constructor de `MqttService`.
  ///
  /// Toma como parámetros:
  /// - [server]: La dirección del servidor MQTT.
  /// - [clientId]: El ID del cliente que se utilizará al conectar.
  ///
  /// Configura el cliente MQTT con el servidor especificado y el ID del cliente,
  /// y establece configuraciones adicionales como el periodo de keep-alive y la
  /// reconexión automática.
  MqttService(String server, String clientId)
      : client = MqttServerClient.withPort(server, clientId, 1883) {
    client.logging(on: true); // Habilita el registro para el cliente MQTT
    client.keepAlivePeriod = 20; // Establece el periodo de keep-alive a 20 segundos
    client.onDisconnected = _onDisconnected; // Asigna un callback para cuando se desconecta
    client.autoReconnect = true; // Habilita la reconexión automática

    // Configura el mensaje de conexión con el ID del cliente y la QoS deseada
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMessage;
  }

  /// Callback que se ejecuta cuando la conexión se desconecta.
  void _onDisconnected() {
    print('Disconnected');
  }

  /// Conecta el cliente MQTT al broker especificado.
  ///
  /// Intenta establecer una conexión con el broker. Si la conexión es exitosa,
  /// imprime "Connected", de lo contrario, imprime un mensaje de error y desconecta
  /// al cliente.
  Future<void> connect() async {
    try {
      print('Attempting to connect to broker...');
      await client.connect(null, null); // Intenta conectar al broker sin autenticación
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('Connected'); // Conexión exitosa
      } else {
        print(
            'Connection failed with state: ${client.connectionStatus?.state}');
        client.disconnect(); // Desconecta en caso de fallo
      }
    } catch (e) {
      print('Connection failed: $e');
      client.disconnect(); // Desconecta si ocurre un error
    }
  }

  /// Escucha los mensajes de un tópico específico y los emite como un stream de valores `double`.
  ///
  /// [topic]: El tópico al cual suscribirse.
  ///
  /// Devuelve un stream de valores `double` que se reciben desde el tópico.
  Stream<double> getValueStream(String topic) async* {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.subscribe(topic, MqttQos.atMostOnce); // Se suscribe al tópico con QoS 0

      // Espera y procesa los mensajes que se publican en el tópico
      await for (final c in client.updates!) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        yield double.tryParse(pt) ?? 0.0; // Convierte el mensaje a double y lo emite
      }
    } else {
      client.disconnect(); // Desconecta si no está conectado
    }
  }
}
