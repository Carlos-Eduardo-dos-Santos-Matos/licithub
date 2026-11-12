/// Formata um valor numérico ou textual no padrão monetário brasileiro (R$ 0.000,00).
String formatarMoeda(dynamic valor) {
  final numero =
      valor is num ? valor : num.tryParse(valor?.toString() ?? '') ?? 0;
  final partes = numero.toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );
  return 'R\$ $inteiro,${partes[1]}';
}
