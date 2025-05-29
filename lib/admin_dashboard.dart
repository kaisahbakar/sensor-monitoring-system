import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String temperature = '--';
  String humidity = '--';
  String relayStatus = '--';
  List<FlSpot> tempData = [];
  List<FlSpot> humData = [];
  List<Map<String, dynamic>> logs = [];

  String selectedView = 'Temperature';
  final _tempController = TextEditingController();
  final _humController = TextEditingController();
  double _tempThreshold = 30.0;
  double _humidityThreshold = 70.0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchThresholds().then((_) => fetchData());
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tempController.dispose();
    _humController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    final url =
        Uri.parse("https://humancc.site/nurkaisah/DHT11/bek_n/fetch.php");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final latest = data.first;
          setState(() {
            temperature = latest['temperature'].toString();
            humidity = latest['humidity'].toString();
            relayStatus = latest['relay_status'].toString(); // 'ON' or 'OFF'
            tempData = List.generate(
              data.length,
              (i) => FlSpot(
                  i.toDouble(), (data[i]['temperature'] as num).toDouble()),
            );
            humData = List.generate(
              data.length,
              (i) =>
                  FlSpot(i.toDouble(), (data[i]['humidity'] as num).toDouble()),
            );
            logs =
                data.take(5).map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> fetchThresholds() async {
    final url = Uri.parse(
        'https://humancc.site/nurkaisah/DHT11/bek_n/get_thresholds.php?user_id=1');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true) {
          setState(() {
            _tempThreshold =
                (json['thresholds']['temp_threshold'] as num).toDouble();
            _humidityThreshold =
                (json['thresholds']['humidity_threshold'] as num).toDouble();
            _tempController.text = _tempThreshold.toString();
            _humController.text = _humidityThreshold.toString();
          });
        }
      }
    } catch (e) {
      print('Failed to fetch thresholds: $e');
    }
  }

  Future<void> updateThresholds() async {
    final url = Uri.parse(
        'https://humancc.site/nurkaisah/DHT11/bek_n/update_thresholds.php');
    final body = jsonEncode({
      'user_id': 1,
      'temp_threshold': double.tryParse(_tempController.text) ?? 30.0,
      'humidity_threshold': double.tryParse(_humController.text) ?? 70.0,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      final result = jsonDecode(response.body);
      if (result['status'] == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Thresholds updated')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed')));
      }
    } catch (e) {
      print('Error updating thresholds: $e');
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget buildChart(List<FlSpot> data, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            backgroundColor: Colors.transparent,
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: data,
                isCurved: true,
                color: color,
                barWidth: 3,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white30),
      ),
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(30),
        isSelected: [
          selectedView == 'Temperature',
          selectedView == 'Humidity',
        ],
        onPressed: (index) {
          setState(() {
            selectedView = index == 0 ? 'Temperature' : 'Humidity';
          });
        },
        color: Colors.white,
        selectedColor: Colors.white,
        fillColor: Colors.blueAccent.withOpacity(0.4),
        borderColor: Colors.transparent,
        selectedBorderColor: Colors.transparent,
        children: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Temperature")),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Humidity")),
        ],
      ),
    );
  }

  Widget buildDataCard(String label, String value, Color start, Color end) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [start, end],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 18, color: Colors.white)),
            SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white))
          ],
        ),
      ),
    );
  }

  Widget buildLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Logs",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: logs
              .map((log) => Container(
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Temp: ${log['temperature']} °C\nHumidity: ${log['humidity']} %\nRelay: ${log['relay_status']}",
                      style: TextStyle(color: Colors.white),
                    ),
                  ))
              .toList(),
        )
      ],
    );
  }

  Widget buildThresholdControls() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Update Thresholds",
              style: TextStyle(color: Colors.white, fontSize: 18)),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tempController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Temp Threshold (°C)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _humController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Humidity Threshold (%)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: updateThresholds,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Set Thresholds"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Admin Dashboard',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout'),
                  content: Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Logout')),
                  ],
                ),
              );
              if (confirm == true) logout();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildToggleButtons(),
            if (selectedView == 'Temperature')
              buildChart(tempData, Colors.orangeAccent),
            if (selectedView == 'Humidity')
              buildChart(humData, Colors.lightBlueAccent),
            SizedBox(height: 20),
            Row(
              children: [
                buildDataCard("Temperature", "$temperature °C",
                    Color(0xFF6D5DF6), Color(0xFF38B6FF)),
                buildDataCard("Humidity", "$humidity %", Color(0xFF38B6FF),
                    Color(0xFF6D5DF6)),
              ],
            ),
            const SizedBox(height: 20),
            Text("Fan Status: $relayStatus",
                style: TextStyle(
                    fontSize: 20,
                    color: relayStatus == 'ON' ? Colors.red : Colors.green)),
            buildThresholdControls(),
            const SizedBox(height: 20),
            buildLogsSection(),
          ],
        ),
      ),
    );
  }
}
