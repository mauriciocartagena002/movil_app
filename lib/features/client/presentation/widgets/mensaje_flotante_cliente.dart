import 'package:flutter/material.dart';

import '../theme/colores_cliente.dart';

SnackBar mensajeFlotanteCliente(
  String mensaje, {
  IconData icono = Icons.info_outline,
}) {
  return SnackBar(
    content: Row(
      children: [
        Icon(icono, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            mensaje,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: ClientColors.red,
    margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}
