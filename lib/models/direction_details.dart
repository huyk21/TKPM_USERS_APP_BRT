abstract class DirectionDetails {
  String? distanceTextString;
  String? durationTextString;
  int? distanceValueDigits;
  int? durationValueDigits;
  String? encodedPoints;
  double? baseFareAmount; // abstract getter

  String get vehicleType;
  String calculateFareAmount(); // abstract method

  static DirectionDetails getSubClass(String vehicleType) {
    if (vehicleType == "Car") return CarDetail();
    if (vehicleType == "Bike") return BikeDetail();
    throw Exception('Invalid vehicle type: $vehicleType');
  }

  DirectionDetails({
    this.distanceTextString,
    this.durationTextString,
    this.distanceValueDigits,
    this.durationValueDigits,
    this.encodedPoints,
    this.baseFareAmount,
  });
}

class CarDetail extends DirectionDetails {
  @override
  String get vehicleType => "Car";

  @override
  String calculateFareAmount()
  {
    double distancePerKmAmount = 0.4;
    double durationPerMinuteAmount = 0.3;

    double totalDistanceTravelFareAmount = (distanceValueDigits! / 1000) * distancePerKmAmount;
    double totalDurationSpendFareAmount = (durationValueDigits! / 60) * durationPerMinuteAmount;

    double overAllTotalFareAmount = baseFareAmount! + totalDistanceTravelFareAmount + totalDurationSpendFareAmount;

    return overAllTotalFareAmount.toStringAsFixed(1);
  }
}

class BikeDetail extends DirectionDetails {
  @override
  String get vehicleType => "Bike";

  @override
  String calculateFareAmount()
  {
    double distancePerKmAmount = 0.4;
    double durationPerMinuteAmount = 0.3;

    double totalDistanceTravelFareAmount = (distanceValueDigits! / 1000) * distancePerKmAmount;
    double totalDurationSpendFareAmount = (durationValueDigits! / 60) * durationPerMinuteAmount;

    double overAllTotalFareAmount = baseFareAmount! + totalDistanceTravelFareAmount + totalDurationSpendFareAmount;

    return overAllTotalFareAmount.toStringAsFixed(1);
  }
}
