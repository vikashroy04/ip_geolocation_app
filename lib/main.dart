import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IP Geolocation',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: IPInfoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class IPInfoScreen extends StatefulWidget {
  @override
  State<IPInfoScreen> createState() => _IPInfoScreenState();
}

class _IPInfoScreenState extends State<IPInfoScreen> {
  String ip = '';
  Map<String, dynamic>? data;
  String? error;
  bool isLoading = false;
  List<String> history = [];

  @override
  void initState() {
    super.initState();
    getOwnIP();
  }

  Future<void> getOwnIP() async {
    try {
      final res = await http.get(Uri.parse('https://api.ipify.org?format=json'),);
      final json = jsonDecode(res.body);
      ip = json['ip'];
      fetchIPInfo();
    } catch (_) {}
  }

  Future<void> fetchIPInfo() async {
    setState(() {
      isLoading = true;
      error = null;
      data = null;
    });

    try {
      final url = Uri.parse('http://ip-api.com/json/$ip');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            data = jsonData;
            history.add(ip);
          });
        } else {
          setState(() {
            error = "Error: ${jsonData['message'] ?? 'Invalid IP'}";
          });
        }
      } else {
        setState(() {
          error = 'HTTP Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: Text('IP Geolocation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter IP Address',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => ip = value,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchIPInfo,
              child: Text('Get Info'),
            ),
            SizedBox(height: 20),
            if (isLoading) Center(child: CircularProgressIndicator(),),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red)),
            if (history.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search History:', style: TextStyle(fontWeight: FontWeight.bold)),
                  for (var h in history.reversed) Text(h, style: TextStyle(fontSize: 15),),
                  Divider(thickness: 2),
                ],
              ),
            if (data != null)
              Expanded(
                child: ListView(
                  children: [
                    Text('Country: ${data!['country']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
                    Text('State: ${data!['regionName']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
                    Text('City: ${data!['city']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
                    Text('ISP: ${data!['isp']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
                    Text('Latitude: ${data!['lat']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
                    Text('Longitude: ${data!['lon']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        final lat = data!['lat'];
                        final lon = data!['lon'];
                        final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
                        launchUrl(Uri.parse(url));
                      },
                      child: Text('Open in Google Maps'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}