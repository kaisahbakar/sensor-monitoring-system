<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

include 'db.php';

$data = json_decode(file_get_contents("php://input"), true);
$user_id = $data['user_id'] ?? '';
$temp_threshold = $data['temp_threshold'] ?? '';
$humidity_threshold = $data['humidity_threshold'] ?? '';

if (empty($user_id) || $temp_threshold === '' || $humidity_threshold === '') {
    echo json_encode(["status" => false, "message" => "Missing fields"]);
    exit;
}

// Check if threshold exists for user
$sql = "SELECT id FROM thresholds WHERE user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    $stmt->close();
    $stmt = $conn->prepare("UPDATE thresholds SET temp_threshold = ?, humidity_threshold = ? WHERE user_id = ?");
    $stmt->bind_param("ddi", $temp_threshold, $humidity_threshold, $user_id);
} else {
    $stmt->close();
    $stmt = $conn->prepare("INSERT INTO thresholds (user_id, temp_threshold, humidity_threshold) VALUES (?, ?, ?)");
    $stmt->bind_param("idd", $user_id, $temp_threshold, $humidity_threshold);
}

$status = $stmt->execute();

if ($status) {
    echo json_encode(["status" => true, "message" => "Thresholds saved"]);
} else {
    echo json_encode(["status" => false, "message" => "Save failed", "error" => $stmt->error]);
}

$stmt->close();
$conn->close();
