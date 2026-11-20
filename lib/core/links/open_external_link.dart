import 'package:url_launcher/url_launcher.dart';

/// Obre [uri] al navegador o a l'app que li correspon (fora d'AProp!).
///
/// Torna `false` si no s'ha pogut obrir.
Future<bool> openExternalLink(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    return false;
  }
}
