import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String temperature = '--';
  String humidity = '--';
  String relayStatus = '--';

  double _tempThreshold = 30.0;
  double _humidityThreshold = 70.0;

  List<FlSpot> tempData = [];
  List<FlSpot> humData = [];

  final _tempController = TextEditingController(text: '30');
  final _humController = TextEditingController(text: '70');

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

  Future<void> fetchThresholds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;
    final deviceId = 'ESP32_001';

    final url = Uri.parse(
        'https://humancc.site/nurkaisah/DHT11/bek_n/get_thresholds.php?user_id=$userId&device_id=$deviceId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true) {
          setState(() {
            _tempThreshold =
                (json['thresholds']['temp_threshold'] ?? 30).toDouble();
            _humidityThreshold =
                (json['thresholds']['humidity_threshold'] ?? 70).toDouble();
            _tempController.text = _tempThreshold.toString();
            _humController.text = _humidityThreshold.toString();
          });
        }
      }
    } catch (e) {
      print('Failed to fetch thresholds: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading thresholds')),
      );
    }
  }

  Future<void> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;

    final url = Uri.parse(
        "https://humancc.site/nurkaisah/DHT11/bek_n/fetch.php?user_id=$userId");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final latest = decoded.first;
          final tempVal = (latest['temperature'] as num).toDouble();
          final humVal = (latest['humidity'] as num).toDouble();
          final bool isRelayOn =
              tempVal > _tempThreshold || humVal > _humidityThreshold;

          setState(() {
            temperature = tempVal.toStringAsFixed(1);
            humidity = humVal.toStringAsFixed(1);
            relayStatus = isRelayOn ? 'ON' : 'OFF';

            tempData = List.generate(
              decoded.length,
              (i) => FlSpot(
                  i.toDouble(), (decoded[i]['temperature'] as num).toDouble()),
            );
            humData = List.generate(
              decoded.length,
              (i) => FlSpot(
                  i.toDouble(), (decoded[i]['humidity'] as num).toDouble()),
            );
          });
        } else {
          // No data
          setState(() {
            temperature = '--';
            humidity = '--';
            relayStatus = '--';
            tempData.clear();
            humData.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No sensor data available')),
          );
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch sensor data')),
      );
    }
  }

  void updateThresholds() async {
    setState(() {
      _tempThreshold = double.tryParse(_tempController.text) ?? 30.0;
      _humidityThreshold = double.tryParse(_humController.text) ?? 70.0;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;

    final url = Uri.parse(
        "https://humancc.site/nurkaisah/DHT11/bek_n/update_thresholds.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "temp_threshold": _tempThreshold,
          "humidity_threshold": _humidityThreshold,
        }),
      );

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thresholds updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${jsonResponse['message']}')),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update thresholds')),
      );
    }

    fetchData();
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget buildChart(String title, List<FlSpot> data, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.transparent,
                minY: data.isNotEmpty
                    ? data.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5
                    : 0,
                maxY: data.isNotEmpty
                    ? data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5
                    : 100,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(0),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: data.isNotEmpty
                          ? (data.length / 4).floorToDouble().clamp(1, 5)
                          : 1,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white30),
                ),
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
        title:
            const Text('User Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildChart("Temperature Graph", tempData, Colors.deepOrangeAccent),
            buildChart("Humidity Graph", humData, Colors.lightBlueAccent),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6D5DF6), Color(0xFF38B6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text("Temperature",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        SizedBox(height: 8),
                        Text("$temperature °C",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF38B6FF), Color(0xFF6D5DF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text("Humidity",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        SizedBox(height: 8),
                        Text("$humidity %",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Fan Status: $relayStatus",
                style: TextStyle(
                    fontSize: 20,
                    color: relayStatus == 'ON' ? Colors.red : Colors.green)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tempController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Temp Threshold (°C)',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white)),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _humController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
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
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: updateThresholds,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Set Thresholds"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await fetchThresholds();
                fetchData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Refresh Data"),
            ),
          ],
        ),
      ),
    );
  }
}
