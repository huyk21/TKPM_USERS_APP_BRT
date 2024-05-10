class AddressModel
{
  String? humanReadableAddress;
  double? latitudePosition;
  double? longitudePosition;
  String? placeID;
  String? placeName;
  String? tag;

  AddressModel({this.humanReadableAddress, this.latitudePosition, this.longitudePosition, this.placeID, this.placeName, this.tag});

  factory AddressModel.fromMap(Map<dynamic, dynamic> data) {
    return AddressModel(
      humanReadableAddress: data['address'] ?? '',
      latitudePosition: data['latitude'] is double ? data['latitude'] : (data['latitude'] as num).toDouble(),
      longitudePosition: data['longitude'] is double ? data['longitude'] : (data['longitude'] as num).toDouble(),
      placeID: data['placeID'] ?? '',
      placeName: data['placeName'] ?? '',
      tag: data['tag'] ?? ''
    );
  }
}