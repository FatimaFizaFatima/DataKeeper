class User {
  final int? id;
  final String name;
  final String phone;
  final String city;
  final String postalCode;
  final String street;

  User({
    this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.postalCode,
    required this.street,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'city': city,
      'postalCode': postalCode,
      'street': street,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    // Handle ID conversion safely
    final dynamic idValue = map['id'];
    final int? parsedId = idValue is int
        ? idValue
        : idValue is String
            ? int.tryParse(idValue)
            : null;

    return User(
      id: parsedId,
      name: _toString(map['name']),
      phone: _toString(map['phone']),
      city: _toString(map['city']),
      postalCode: _toString(map['postalCode']),
      street: _toString(map['street']),
    );
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}
