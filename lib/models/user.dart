class AppUser {
  final String id;
  final String fullName;
  final String cpf;
  final String contact;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.cpf,
    required this.contact,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  AppUser copyWith({
    String? fullName,
    String? cpf,
    String? contact,
    String? avatarUrl,
    DateTime? updatedAt,
  }) => AppUser(
    id: id,
    fullName: fullName ?? this.fullName,
    cpf: cpf ?? this.cpf,
    contact: contact ?? this.contact,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'cpf': cpf,
    'contact': contact,
    'avatarUrl': avatarUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    cpf: json['cpf'] as String,
    contact: json['contact'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}
