class Vacancy {
  final int id;
  final double  latitude;
  final double  longitude;
  Vacancy({this.id, this.latitude, this.longitude});

  factory Vacancy.fromJSON(Map<String, dynamic> json){
    return Vacancy(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude
  };
}