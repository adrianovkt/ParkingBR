enum PlateType {
  old,
  mercosul,
  invalid,
}

class PlateValidator {
  static PlateType identify(String plate) {
    // Remove espaços e hífens para validar a sequência bruta
    final cleanPlate = plate.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    
    if (cleanPlate.length != 7) return PlateType.invalid;

    // Antiga (1990-2018): 3 letras e 4 números (ABC1234)
    final oldRegEx = RegExp(r'^[A-Z]{3}[0-9]{4}$');
    if (oldRegEx.hasMatch(cleanPlate)) return PlateType.old;

    // Mercosul (Atual): 3 letras, 1 número, 1 letra, 2 números (ABC1C34)
    final mercosulRegEx = RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$');
    if (mercosulRegEx.hasMatch(cleanPlate)) return PlateType.mercosul;

    return PlateType.invalid;
  }

  static String format(String plate) {
    final cleanPlate = plate.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    final type = identify(cleanPlate);

    if (type == PlateType.old && cleanPlate.length == 7) {
      // Formato LLL-NNNN
      return '${cleanPlate.substring(0, 3)}-${cleanPlate.substring(3)}';
    }
    
    // Mercosul não usa hífen oficialmente na representação alfanumérica
    return cleanPlate;
  }

  static String getLabel(PlateType type) {
    return switch (type) {
      PlateType.old => 'Placa Antiga',
      PlateType.mercosul => 'Placa Mercosul',
      PlateType.invalid => 'Placa Inválida',
    };
  }
}
