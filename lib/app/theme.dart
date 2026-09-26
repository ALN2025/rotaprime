import 'package:flutter/material.dart';



class AppColors {

  static const background = Color(0xFF0A0A0A);

  static const sheet = Color(0xFF121212);

  static const card = Color(0xFF1A1A1A);

  static const orange = Color(0xFFFF6B00);

  static const accent = orange;

  /// Rota no mapa — laranja suave (não tapa nomes de rua).
  static Color get routeLineCore => orange.withValues(alpha: 0.34);

  static Color get routeLineHalo => orange.withValues(alpha: 0.18);

  /// Rota ativa — laranja Circuit (rua visível por baixo / nomes legíveis).
  static Color get activeDeliveryRouteFill => orange.withValues(alpha: 0.48);

  static Color get activeDeliveryRouteEdge => orange.withValues(alpha: 0.22);

  static const successGreen = Color(0xFF4CAF50);

  /// Paradas pendentes no mapa de entrega (legenda).
  static const stopPending = Color(0xFF78909C);

  static const stopFailed = Color(0xFFD32F2F);

  static const timelineLine = orange;

  static const muted = Color(0xFF9E9E9E);

}



/// Botões laranja sempre com texto/ícone branco (legível no APK).

ButtonStyle primaryOrangeButtonStyle({EdgeInsetsGeometry? padding}) {

  return ElevatedButton.styleFrom(

    backgroundColor: AppColors.orange,

    foregroundColor: Colors.white,

    disabledBackgroundColor: const Color(0xFF5C3A1A),

    disabledForegroundColor: Colors.white54,

    elevation: 2,

    padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

    textStyle: const TextStyle(

      fontWeight: FontWeight.bold,

      fontSize: 15,

      color: Colors.white,

    ),

    iconColor: Colors.white,

  );

}



ButtonStyle successButtonStyle({EdgeInsetsGeometry? padding}) {

  return ElevatedButton.styleFrom(

    backgroundColor: AppColors.successGreen,

    foregroundColor: Colors.white,

    textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),

    padding: padding,

  );

}



ThemeData buildDarkTheme() {

  return ThemeData(

    brightness: Brightness.dark,

    scaffoldBackgroundColor: AppColors.background,

    colorScheme: const ColorScheme.dark(

      surface: AppColors.background,

      primary: AppColors.orange,

      onPrimary: Colors.white,

      secondary: AppColors.orange,

      onSecondary: Colors.white,

    ),

    appBarTheme: const AppBarTheme(

      backgroundColor: Colors.transparent,

      elevation: 0,

      foregroundColor: Colors.white,

    ),

    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryOrangeButtonStyle()),

    filledButtonTheme: FilledButtonThemeData(style: primaryOrangeButtonStyle()),

    outlinedButtonTheme: OutlinedButtonThemeData(

      style: OutlinedButton.styleFrom(

        foregroundColor: Colors.white,

        side: const BorderSide(color: Colors.white38),

        textStyle: const TextStyle(fontWeight: FontWeight.w600),

      ),

    ),

    textButtonTheme: TextButtonThemeData(

      style: TextButton.styleFrom(

        foregroundColor: AppColors.orange,

        textStyle: const TextStyle(fontWeight: FontWeight.w600),

      ),

    ),

    checkboxTheme: CheckboxThemeData(

      fillColor: WidgetStateProperty.resolveWith((states) {

        if (states.contains(WidgetState.selected)) return Colors.white;

        return Colors.transparent;

      }),

      checkColor: WidgetStateProperty.all(AppColors.orange),

      side: const BorderSide(color: Colors.white, width: 2),

    ),

    dividerColor: const Color(0xFF2A2A2A),

  );

}


