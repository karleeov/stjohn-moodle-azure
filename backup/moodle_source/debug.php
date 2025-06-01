<?php
echo "<h1>Debug Information</h1>";
echo "<p>Current time: " . date('Y-m-d H:i:s') . "</p>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Current directory: " . getcwd() . "</p>";
echo "<p>Document root: " . $_SERVER['DOCUMENT_ROOT'] . "</p>";

echo "<h2>File Checks</h2>";
echo "<p>config.php exists: " . (file_exists('./config.php') ? 'YES' : 'NO') . "</p>";
echo "<p>index.php exists: " . (file_exists('./index.php') ? 'YES' : 'NO') . "</p>";
echo "<p>install.php exists: " . (file_exists('./install.php') ? 'YES' : 'NO') . "</p>";

echo "<h2>Directory Contents</h2>";
echo "<ul>";
$files = scandir('.');
foreach($files as $file) {
    if($file != '.' && $file != '..') {
        echo "<li>$file</li>";
    }
}
echo "</ul>";

echo "<h2>Config.php Test</h2>";
if (file_exists('./config.php')) {
    try {
        include_once('./config.php');
        echo "<p style='color: green;'>Config.php loaded successfully</p>";
        echo "<p>WWW Root: " . (isset($CFG->wwwroot) ? $CFG->wwwroot : 'NOT SET') . "</p>";
        echo "<p>Data Root: " . (isset($CFG->dataroot) ? $CFG->dataroot : 'NOT SET') . "</p>";
        echo "<p>DB Host: " . (isset($CFG->dbhost) ? $CFG->dbhost : 'NOT SET') . "</p>";
        echo "<p>DB Name: " . (isset($CFG->dbname) ? $CFG->dbname : 'NOT SET') . "</p>";
        echo "<p>DB User: " . (isset($CFG->dbuser) ? $CFG->dbuser : 'NOT SET') . "</p>";
        echo "<p>DB Pass: " . (isset($CFG->dbpass) ? (strlen($CFG->dbpass) > 0 ? 'SET (' . strlen($CFG->dbpass) . ' chars)' : 'EMPTY') : 'NOT SET') . "</p>";
    } catch (Exception $e) {
        echo "<p style='color: red;'>Error loading config.php: " . $e->getMessage() . "</p>";
    }
} else {
    echo "<p style='color: red;'>config.php not found</p>";
}

echo "<h2>Database Connection Test</h2>";
if (isset($CFG) && isset($CFG->dbhost)) {
    try {
        $pdo = new PDO("mysql:host={$CFG->dbhost};dbname={$CFG->dbname}", $CFG->dbuser, $CFG->dbpass);
        echo "<p style='color: green;'>Database connection successful!</p>";
    } catch(PDOException $e) {
        echo "<p style='color: red;'>Database connection failed: " . $e->getMessage() . "</p>";
    }
}

echo "<h2>Moodle Setup Test</h2>";
if (isset($CFG)) {
    try {
        if (file_exists($CFG->dirroot . '/lib/setup.php')) {
            echo "<p>lib/setup.php exists</p>";
            // Don't actually include it as it might cause issues
        } else {
            echo "<p style='color: red;'>lib/setup.php not found</p>";
        }
    } catch (Exception $e) {
        echo "<p style='color: red;'>Error checking Moodle setup: " . $e->getMessage() . "</p>";
    }
}
?>
