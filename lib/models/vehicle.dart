class Vehicle {
  final String id;
  final String plate;
  final String model;
  final String color;
  final String ownerName;
  final String ownerCpf;
  final String ownerContact;
  final bool archived;

  Vehicle({
    required this.id,
    required this.plate,
    required this.model,
    required this.color,
    required this.ownerName,
    required this.ownerCpf,
    required this.ownerContact,
    this.archived = false,
  });

  Vehicle copyWith({
    String? id,
    String? plate,
    String? model,
    String? color,
    String? ownerName,
    String? ownerCpf,
    String? ownerContact,
    bool? archived,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      model: model ?? this.model,
      color: color ?? this.color,
      ownerName: ownerName ?? this.ownerName,
      ownerCpf: ownerCpf ?? this.ownerCpf,
      ownerContact: ownerContact ?? this.ownerContact,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate': plate,
      'model': model,
      'color': color,
      'ownerName': ownerName,
      'ownerCpf': ownerCpf,
      'ownerContact': ownerContact,
      'archived': archived,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      plate: json['plate'],
      model: json['model'],
      color: json['color'],
      ownerName: json['ownerName'] as String? ?? '',
      ownerCpf: json['ownerCpf'] as String? ?? '',
      ownerContact: json['ownerContact'] as String? ?? '',
      archived: json['archived'] as bool? ?? false,
    );
  }

  Map<String, Object?> toDatabase() => {
    'id': id,
    'plate': plate.replaceAll('-', ''),
    'model': model,
    'color': color,
    'owner_name': ownerName,
    'owner_cpf': ownerCpf,
    'owner_contact': ownerContact,
    'archived': archived ? 1 : 0,
  };

  factory Vehicle.fromDatabase(Map<String, Object?> row) => Vehicle(
    id: row['id']! as String,
    plate: row['plate']! as String,
    model: row['model']! as String,
    color: row['color']! as String,
    ownerName: row['owner_name']! as String,
    ownerCpf: row['owner_cpf']! as String,
    ownerContact: row['owner_contact']! as String,
    archived: row['archived'] == 1,
  );
}
