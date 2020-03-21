import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:user_location/user_location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:vaga_azul/vacancy.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:location/location.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaga Azul',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ADD THIS
  MapController mapController = MapController();
  UserLocationOptions userLocationOptions;
  // ADD THIS
  List<Marker> markers = [];
  List<Vacancy> fromServer;
  StreamController<LatLng> markerLocationStream = StreamController();
  double _circleDistance(double latx, double longx, double laty, double longy){
      return  sqrt(pow(latx-laty, 2) + pow(longx - longy, 2));
  }
  delete(double lat, double long){
    for(int i = 0; i < fromServer.length; i++){
      if(fromServer[i].latitude == lat && fromServer[i].longitude == long){
        print("https://vaga-azul.herokuapp.com/api/v1/vacancies/" + fromServer[i].id.toString());
        final response = http.delete("https://vaga-azul.herokuapp.com/api/v1/vacancies/" + fromServer[i].id.toString(),
            headers: {"Content-Type": "application/json"}
        );
        //markers.removeWhere((item) => item.point.latitude == lat && item.point.longitude == long);
        //markers.removeWhere((item) => item.height == 40.0);
        markers = [];
        response.then((value){
          if (value.statusCode == 200){
            setState(() {});
            showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {

                  Widget okButton = FlatButton(
                    child: Text("OK"),
                    onPressed: () { Navigator.of(context).pop(); },
                  );

                  return new AlertDialog(
                    title: new Text('Localização removida'),
                    content: Text('Vaga excluída com sucesso'),
                    actions: [
                      okButton,
                    ],
                  );
                });
          }
        });
        return response;
      }
    }
  }
  addMarker() {
    final Location location = new Location();
    var locationResult = location.getLocation();
    locationResult.then((value){
      print(value.latitude);
      print(value.longitude);
      bool sendData = true;
      print(sendData);
      for(int i = 0; i < markers.length; i++){
        print(_circleDistance(markers[i].point.latitude, markers[i].point.longitude, value.latitude, value.longitude));
        print(i);
        if(markers[i].width == 40.0)
        if(_circleDistance(markers[i].point.latitude, markers[i].point.longitude, value.latitude, value.longitude) <= 0.000020){
          sendData = false;
          break;
        }
      }

      if(sendData == true) {
        Map data = {
          'latitude': value.latitude.toString(),
          'longitude': value.longitude.toString()
        };
        final body = json.encode(data);
        final response = http.post("https://vaga-azul.herokuapp.com/api/v1/vacancies/",
            headers: {"Content-Type": "application/json"},
            body: body
        );
        response.then((value){
          if(value.statusCode == 200)
            setState(() {});
        });
        print(response);
        /*
        markers.add(new Marker(
          width: 40.0,
          height: 40.0,
          point: LatLng(value.latitude, value.longitude),
          builder: (ctx) => Container(
            child: IconButton(
              icon: Icon(Icons.location_on),
              color: Colors.blue,
              iconSize: 40.0,
              onPressed: () {
                delete(value.latitude, value.longitude);
              },
            ),
          ),
        ));
        */

      }else{

        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {

              Widget okButton = FlatButton(
                child: Text("OK"),
                onPressed: () { Navigator.of(context).pop(); },
              );

              return new AlertDialog(
                title: new Text('Localização não incluída'),
                content: Text('Aparentemente já existe uma localização salva próximo de onde você está'),
                actions: [
                  okButton,
                ],
              );
            });
      }
    });
  }

  Widget loadMap(){
    return FutureBuilder(
      future: fetchVacancies(http.Client()),
      builder: (context, snapshot) {
        if(markers.length > 2)
          markers.removeRange(0, markers.length-1);
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        fromServer = snapshot.data;
        for(int i = 0; i < snapshot.data.length; i++){
          markers.add(new Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(snapshot.data[i].latitude, snapshot.data[i].longitude),
            builder: (ctx) => Container(
              child: IconButton(
                icon: Icon(Icons.location_on),
                color: Colors.blue,
                iconSize: 40.0,
                onPressed: () {
                  delete(snapshot.data[i].latitude, snapshot.data[i].longitude);
                },
              ),
            ),
          ));
        }

        for(int i = 0; i < markers.length; i++)
          print(markers[i].point.latitude.toString() + " " + markers[i].point.longitude.toString());

        return new FlutterMap(
          options: MapOptions(
            center: LatLng(0,0),
            zoom: 15.0,
            plugins: [
              // ADD THIS
              UserLocationPlugin(),
            ],
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: "https://api.tiles.mapbox.com/v4/"
                  "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
              additionalOptions: {
                'accessToken': 'pk.eyJ1IjoiY2FybG9zZmVsaXgiLCJhIjoiY2s4MG1hcGlwMDEyNTNmbnRqcGNrNjVkcCJ9.ZPTF_uUKwiYDnCY70uhrZA',
                'id': 'mapbox.streets',
              },
            ),
            // ADD THIS
            MarkerLayerOptions(markers: markers),
            // ADD THIS
            userLocationOptions,
          ],
          // ADD THIS
          mapController: mapController,
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // You can use the userLocationOptions object to change the properties
    // of UserLocationOptions in runtime
    userLocationOptions = UserLocationOptions(

      updateMapLocationOnPositionChange: true,
      context: context,
      mapController: mapController,
      markers: markers,
    );
    return Scaffold(
        appBar: AppBar(
          title: Text("Vaga Azul"),
          leading: new IconButton(icon: Icon(Icons.add), onPressed: addMarker)
        ),
        body: loadMap());
  }

  @override
  void dispose() {
    if(!markerLocationStream.isClosed)
      markerLocationStream.close();
    super.dispose();
  }
}



Future<List<Vacancy>> fetchVacancies(http.Client client) async {
  final response = await client.get(
      'https://vaga-azul.herokuapp.com/api/v1/vacancies/');
  return compute(parseVacancies, response.body);
}
List<Vacancy> parseVacancies(String responseBody){
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Vacancy>((json) => Vacancy.fromJSON(json)).toList();
}

