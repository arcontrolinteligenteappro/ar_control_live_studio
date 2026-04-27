// Asegúrese de tener los imports necesarios arriba

class RemoteNode {
  // 1. Declarar las variables que el NodeManager intenta enviar
  final String id;
  final String ip;
  final String name;
  final String type; 

  // 2. Crear el constructor con parámetros nombrados requeridos
  RemoteNode({
    required this.id,
    required this.ip,
    required this.name,
    required this.type,
  });

  // ... (Aquí debajo mantenga intacto el resto de los métodos que 
  // ya tenía programados en esta clase, como su debugPrint, etc.)
}