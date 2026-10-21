/// «Gratuït» si el preu és 0; si no, l'import en euros amb coma decimal:
/// «12 €», «12,50 €».
String formatActivityPrice(double price) {
  if (price == 0) return 'Gratuït';

  final cents = (price * 100).round();
  final euros = cents ~/ 100;
  final rest = cents % 100;
  return rest == 0 ? '$euros €' : '$euros,${rest.toString().padLeft(2, '0')} €';
}
