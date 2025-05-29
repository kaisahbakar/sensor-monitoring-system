<?php
// Allow CORS
header("Access-Control-Allow-Origin: *"); 
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// Database config
$host = "localhost";
$db   = "humancmt_KB_DHT11";
$user = "humancmt_KaisahBakar";
$pass = "@Kairoq88";

// Connect to MySQL
$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => "Database connection failed: " . $conn->connect_error
    ]));
}

// Get JSON input
$input = json_decode(file_get_contents("php://input"), true);

// Validate fields
if (
    isset($input['temperature']) &&
    isset($input['humidity']) &&
    isset($input['relay_status']) &&
    isset($input['device_id'])
) {
    $temperature   = floatval($input['temperature']);
    $humidity      = floatval($input['humidity']);
    $relay_status  = $input['relay_status'] === "ON" ? 1 : 0;
    $device_id     = $conn->real_escape_string($input['device_id']);

    // Insert without user_id
    $stmt = $conn->prepare("INSERT INTO sensor_data (device_id, temperature, humidity, relay_status, timestamp) VALUES (?, ?, ?, ?, NOW())");
    $stmt->bind_param("sddi", $device_id, $temperature, $humidity, $relay_status);

    if ($stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "Data inserted."]);
    } else {
        echo json_encode(["status" => "error", "message" => "Insert failed.", "error" => $stmt->error]);
    }

    $stmt->close();
} else {
    echo json_encode(["status" => "error", "message" => "Missing one or more required fields."]);
}

$conn->close();
?>
