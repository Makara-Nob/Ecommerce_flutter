class AddressModel {
  final int id;
  final String title;
  final String recipientName;
  final String phoneNumber;
  final String streetAddress;
  final String city;
  final String? state;
  final String? zipCode;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.title,
    required this.recipientName,
    required this.phoneNumber,
    required this.streetAddress,
    required this.city,
    this.state,
    this.zipCode,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      recipientName: json['recipientName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      streetAddress: json['streetAddress'] ?? '',
      city: json['city'] ?? '',
      state: json['state'],
      zipCode: json['zipCode'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'isDefault': isDefault,
    };
  }
}
