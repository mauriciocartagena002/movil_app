import 'package:flutter/material.dart';
import '../../../../core/servicios/servicio_supabase.dart';
import '../../data/repositorio_peso_cliente_supabase.dart';
class PantallaPeso extends StatefulWidget {
  const PantallaPeso({super.key});

  @override
  State<PantallaPeso> createState() => _PantallaPesoState();
}

class _PantallaPesoState extends State<PantallaPeso> {
  final _repositorio = const RepositorioPesoClienteSupabase();
  final _formKey = GlobalKey<FormState>();
  final _pesoController = TextEditingController();

  List<RegistroPeso> _registros = [];
  bool _cargando = true;
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarRegistros();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _cargarRegistros() async {
    setState(() => _cargando = true);
    try {
      final usuarioId = ServicioSupabase.cliente.auth.currentUser?.id;
      if (usuarioId != null) {
        final datos = await _repositorio.obtenerRegistros(usuarioId);
        setState(() => _registros = datos);
      }
    } catch (e) {
      _mostrarMensaje('Error al cargar datos: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarOActualizar({RegistroPeso? registroExistente}) async {
    if (!_formKey.currentState!.validate()) return;

    final pesoDouble = double.tryParse(_pesoController.text.replaceAll(',', '.'));
    if (pesoDouble == null) return;

    final usuarioId = ServicioSupabase.cliente.auth.currentUser?.id;
    if (usuarioId == null) return;

    Navigator.pop(context); // Cierra el modal de formulario

    try {
      if (registroExistente == null) {
        await _repositorio.crearRegistro(
          usuarioId: usuarioId,
          peso: pesoDouble,
          fecha: _fechaSeleccionada,
        );
        _mostrarMensaje('Peso registrado con éxito');
      } else {
        await _repositorio.actualizarRegistro(
          id: registroExistente.id,
          peso: pesoDouble,
          fecha: _fechaSeleccionada,
        );
        _mostrarMensaje('Registro actualizado con éxito');
      }
      _cargarRegistros();
    } catch (e) {
      _mostrarMensaje('Error al guardar: $e');
    }
  }

  Future<void> _eliminar(String id) async {
    try {
      await _repositorio.eliminarRegistro(id);
      _mostrarMensaje('Registro eliminado');
      _cargarRegistros();
    } catch (e) {
      _mostrarMensaje('Error al eliminar: $e');
    }
  }

  void _mostrarFormulario({RegistroPeso? registro}) {
    if (registro != null) {
      _pesoController.text = registro.peso.toString();
      _fechaSeleccionada = registro.fecha;
    } else {
      _pesoController.clear();
      _fechaSeleccionada = DateTime.now();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                registro == null ? 'Nuevo Registro' : 'Editar Registro',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _pesoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Ingresa un peso';
                  final numVal = double.tryParse(val.replaceAll(',', '.'));
                  if (numVal == null || numVal <= 0 || numVal > 500) {
                    return 'Ingresa un peso válido (1 - 500 kg)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () async {
                  final seleccion = await showDatePicker(
                    context: context,
                    initialDate: _fechaSeleccionada,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (seleccion != null) {
                    setState(() => _fechaSeleccionada = seleccion);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  'Fecha: ${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _guardarOActualizar(registroExistente: registro),
                child: Text(registro == null ? 'Guardar' : 'Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Historial de Peso')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _registros.isEmpty
              ? const Center(child: Text('No hay registros de peso aún.'))
              : ListView.builder(
                  itemCount: _registros.length,
                  itemBuilder: (ctx, i) {
                    final item = _registros[i];
                    return ListTile(
                      leading: const Icon(Icons.monitor_weight),
                      title: Text('${item.peso} kg'),
                      subtitle: Text(
                        '${item.fecha.day}/${item.fecha.month}/${item.fecha.year}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _mostrarFormulario(registro: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminar(item.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}