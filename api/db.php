<?php
$servername = "localhost";
$username = "humancmt_KaisahBakar";
$password = "@Kairoq88";
$database = "humancmt_KB_DHT11";

$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
