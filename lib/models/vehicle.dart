class Vehicle {
  final String id;
  final String plate;
  final String model;
  final String color;
  final String ownerName;
  final String ownerCpf;
  final String ownerContact;
  final String? ownerId;
  final String? photoUrl;

  Vehicle({
    required this.id,
    required this.plate,
    required this.model,
    required this.color,
    required this.ownerName,
    required this.ownerCpf,
    required this.ownerContact,
    this.ownerId,
    this.photoUrl,
  });

  Vehicle copyWith({
    String? id,
    String? plate,
    String? model,
    String? color,
    String? ownerName,
    String? ownerCpf,
    String? ownerContact,
    String? ownerId,
    String? photoUrl,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      model: model ?? this.model,
      color: color ?? this.color,
      ownerName: ownerName ?? this.ownerName,
      ownerCpf: ownerCpf ?? this.ownerCpf,
      ownerContact: ownerContact ?? this.ownerContact,
      ownerId: ownerId ?? this.ownerId,
      photoUrl: photoUrl ?? this.photoUrl,
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
      'ownerId': ownerId,
      'photoUrl': photoUrl,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      plate: json['plate'],
      model: json['model'],
      color: json['color'],
      ownerName: json['ownerName'],
      ownerCpf: json['ownerCpf'],
      ownerContact: json['ownerContact'],
      ownerId: json['ownerId'],
      photoUrl: json['photoUrl'],
    );
  }
}
