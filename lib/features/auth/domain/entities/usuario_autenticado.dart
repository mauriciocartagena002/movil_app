class UsuarioAutenticado {
  const UsuarioAutenticado({
    required this.id,
    required this.correo,
    required this.nombreCompleto,
    required this.rol,
    required this.idPublico,
  });

  final String id;
  final String correo;
  final String nombreCompleto;
  final String rol;
  final String idPublico;

  bool get esAdministrador => rol == 'administrador';
}
