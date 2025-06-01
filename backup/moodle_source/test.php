<?php
// Simple test file to check if PHP is working
echo "<h1>PHP Test Page</h1>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Server Software: " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<p>Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "</p>";
echo "<p>Current Directory: " . getcwd() . "</p>";
echo "<p>Files in current directory:</p>";
echo "<ul>";
$files = scandir('.');
foreach($files as $file) {
    if($file != '.' && $file != '..') {
        echo "<li>$file</li>";
    }
}
echo "</ul>";

// Test database connection
echo "<h2>Database Connection Test</h2>";
$host = 'moodledb0530.mysql.database.azure.com:3306';
$dbname = 'moodledb';
$username = 'moodleadmin@moodledb0530';

echo "<p>Attempting to connect to: $host</p>";
echo "<p>Database: $dbname</p>";
echo "<p>Username: $username</p>";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, 'YOUR_MYSQL_PASSWORD_HERE');
    echo "<p style='color: green;'>Database connection: FAILED - Password not set</p>";
} catch(PDOException $e) {
    echo "<p style='color: red;'>Database connection error: " . $e->getMessage() . "</p>";
}

phpinfo();
?>
