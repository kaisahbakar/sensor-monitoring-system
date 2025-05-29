<?php
include 'db.php';
header("Content-Type: application/json");

$device_id = $_GET['device_id'] ?? '';

if (empty($device_id)) {
    echo json_encode(["status" => false, "message" => "Missing device_id"]);
    exit;
}

// Get the latest threshold set by a user who used this device
$query = "SELECT t.temp_threshold, t.humidity_threshold 
          FROM device_users du
          JOIN thresholds t ON du.user_id = t.user_id
          WHERE du.device_id = ?
          ORDER BY t.updated_at DESC LIMIT 1";

$stmt = $conn->prepare($query);
$stmt->bind_param("s", $device_id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode([
        "status" => true,
        "thresholds" => [
            "temp_threshold" => (float)$row['temp_threshold'],
            "humidity_threshold" => (float)$row['humidity_threshold']
        ]
    ]);
} else {
    echo json_encode(["status" => false, "message" => "No threshold found for this device"]);
}

$stmt->close();
$conn->close();
?>
