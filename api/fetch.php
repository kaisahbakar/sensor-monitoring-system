<?php
header("Access-Control-Allow-Origin: *"); 
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'db.php';

$query = "SELECT id, temperature, humidity, relay_status, timestamp 
          FROM sensor_data 
          ORDER BY timestamp DESC 
          LIMIT 50";

$result = $conn->query($query);

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = [
        'id' => (int)$row['id'],
        'temperature' => (float)$row['temperature'],
        'humidity' => (float)$row['humidity'],
        'relay_status' => $row['relay_status'] == 1 ? 'ON' : 'OFF',
        'timestamp' => $row['timestamp']
    ];
}

echo json_encode($data, JSON_PRETTY_PRINT);

$conn->close();
?>
