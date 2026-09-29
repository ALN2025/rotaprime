/// Textos de versão exibidos na splash e configurações.
class AppInfo {
  AppInfo._();

  static const brandLine = 'ALN SYSTEM';
  static const productName = 'ROTA PRIME';
  /// Mantenha alinhado ao `version:` do pubspec.yaml.
  static const displayVersion = '1.2.8';
  static const buildNumber = '39';
  static const shortVersionLabel = 'v$displayVersion';
  static const fullVersionLabel = 'Versão $displayVersion (build $buildNumber)';

  /// Rodapé de configurações — estilo Spoke (ex.: Spoke-v3.68.15).
  static const settingsVersionLine = '$productName-v$displayVersion';
}
