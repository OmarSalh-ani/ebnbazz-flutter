class ParentFollowupModel {
  final String? parentName;
  final String? address;
  final String? maritalStatus;

  const ParentFollowupModel({
    this.parentName,
    this.address,
    this.maritalStatus,
  });

  factory ParentFollowupModel.fromJson(Map<String, dynamic> json) {
    return ParentFollowupModel(
      parentName: json['parentName'] as String?,
      address: json['address'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'parentName': parentName,
        'address': address,
        'maritalStatus': maritalStatus,
      };
}
