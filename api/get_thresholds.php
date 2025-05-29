<?php
include 'db.php';
header('Content-Type: application/json');

$user_id = $_GET['user_id'] ?? '';

if (empty($user_id)) {
    echo json_encode(["status" => false, "message" => "Missing user_id"]);
    exit;
}

$sql = "SELECT temp_threshold, humidity_threshold FROM thresholds WHERE user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode(["status" => true, "thresholds" => $row]);
} else {
    echo json_encode(["status" => false, "message" => "Thresholds not found"]);
}

$stmt->close();
$conn->close();
?>
