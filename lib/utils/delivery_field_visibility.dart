class DeliveryFieldVisibility {
  static const address = 'Destination Address';
  static const spxTn = 'SPX TN';
  static const bairro = 'Bairro';
  static const city = 'City';
  static const zipcode = 'Zipcode';
  static const atId = 'AT ID';
  static const sequence = 'Sequence';
  static const stop = 'Stop';
  static const packageQty = 'Package Qty';

  /// Endereço sempre visível na entrega; demais campos só se marcados antes de importar.
  static bool show(Set<String> selected, String field) {
    if (field == address) return true;
    return selected.contains(field);
  }
}
