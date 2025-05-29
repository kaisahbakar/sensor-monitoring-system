<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

$user_id = intval($data['user_id']);
$device_id = $data['device_id'];

if ($user_id && $device_id) {
    $stmt = $conn->prepare("REPLACE INTO device_users (device_id, user_id) VALUES (?, ?)");
    $stmt->bind_param("si", $device_id, $user_id);

    if ($stmt->execute()) {
        echo json_encode(["status" => true, "message" => "Device-user link created."]);
    } else {
        echo json_encode(["status" => false, "message" => "Insert failed."]);
    }
    $stmt->close();
} else {
    echo json_encode(["status" => false, "message" => "Missing data"]);
}

$conn->close();
?>
