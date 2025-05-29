<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

include 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "message" => "Only POST method is allowed"]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

$username = trim($data['username'] ?? '');
$password = trim($data['password'] ?? '');

if (empty($username) || empty($password)) {
    echo json_encode(["status" => false, "message" => "Username or password is missing"]);
    exit;
}

$stmt = $conn->prepare("SELECT id, username, password, role FROM users WHERE username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $user = $result->fetch_assoc();

    // 🔐 Plaintext check (consider hashing in production)
    if ($password === $user['password']) {
        echo json_encode([
            "status" => true,
            "message" => "Login successful",
            "user_id" => $user['id'],               // ✅ for Flutter
            "username" => $user['username'],
            "role" => $user['role']
        ]);
    } else {
        echo json_encode(["status" => false, "message" => "Incorrect password"]);
    }
} else {
    echo json_encode(["status" => false, "message" => "User not found"]);
}

$stmt->close();
$conn->close();
?>
