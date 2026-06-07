import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Paleta Terrosa (idêntica ao desktop) ──────────────────────────────────
  static const Color corPrimaria   = Color(0xFFA0522D);
  static const Color corSecundaria = Color(0xFFFF8C42);
  static const Color corFundo      = Color(0xFFECE0D4);
  static const Color corCard       = Color(0xFFE6D4BA);
  static const Color corSidebar    = Color(0xFFE6D4BA);
  static const Color corBorda      = Color(0xFF563903);
  static const Color corTexto      = Color(0xFF2C2C2C);
  static const Color corSubtexto   = Color(0xFF4A4A4A);
  static const Color corDestaque   = Color(0xFFCC7722);
  static const Color corErro       = Color(0xFFC62828);
  static const Color corSucesso    = Color(0xFF388E3C);

  // ── ThemeData global ─────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: corFundo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: corPrimaria,
      primary: corPrimaria,
      secondary: corSecundaria,
      surface: corCard,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: corFundo,
      foregroundColor: corTexto,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.roboto(
        color: corDestaque,
        fontSize: 22,
        fontWeight: FontWeight.w400,
      ),
      iconTheme: const IconThemeData(color: corPrimaria),
    ),
    textTheme: GoogleFonts.robotoTextTheme().copyWith(
      bodyLarge:  const TextStyle(color: corTexto),
      bodyMedium: const TextStyle(color: corTexto),
      titleLarge: TextStyle(color: corTexto, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: corCard,
      labelStyle: const TextStyle(color: corSubtexto),
      hintStyle: TextStyle(color: corSubtexto.withOpacity(0.55)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: corBorda, width: 0.6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: corBorda.withOpacity(0.45), width: 0.6),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: corPrimaria, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: corErro, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: corErro, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: corPrimaria,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: corSubtexto),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: corSidebar),
    dividerTheme: const DividerThemeData(color: corBorda, thickness: 0.5),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: corPrimaria),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: corPrimaria,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: corTexto,
      iconColor: corPrimaria,
    ),
  );

  // ── Helpers de widget reutilizáveis ───────────────────────────────────────

  /// Card com borda esquerda colorida — padrão do desktop
  static Widget card({
    required Widget child,
    Color? borderColor,
    EdgeInsets? padding,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor ?? corPrimaria, width: 4),
          top:    BorderSide(color: corBorda.withOpacity(0.3), width: 0.5),
          right:  BorderSide(color: corBorda.withOpacity(0.3), width: 0.5),
          bottom: BorderSide(color: corBorda.withOpacity(0.3), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: corPrimaria.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Seção com título e subtítulo — padrão do desktop
  static Widget pageHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: corTexto)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(fontSize: 13, color: corSubtexto)),
      ],
    );
  }
}
