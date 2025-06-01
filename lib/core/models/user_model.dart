class UserModel {
  final String id;
  final String fullName;
  final String email;
  // Add other fields as needed

  UserModel({required this.id, required this.fullName, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '', // Handle potential int IDs
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'fullName': fullName, 'email': email};
  }
}
