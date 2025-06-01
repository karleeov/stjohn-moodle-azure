<?php
// Emergency Moodle index.php - Temporary file while main deployment completes
// This file will be replaced when the full Moodle deployment finishes

// Check if the main Moodle files exist
$moodle_files_exist = file_exists('config.php') && file_exists('lib/moodlelib.php');

if ($moodle_files_exist) {
    // Main Moodle files are available, redirect to proper Moodle
    header('Location: /moodle_index.php');
    exit;
}

// Show status page while deployment is in progress
?>
<!DOCTYPE html>
<html>
<head>
    <title>Moodle - Deployment in Progress</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="refresh" content="15">
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; display: flex; align-items: center; justify-content: center;
        }
        .container { 
            max-width: 600px; background: white; padding: 40px; border-radius: 12px; 
            box-shadow: 0 10px 30px rgba(0,0,0,0.2); text-align: center;
        }
        .logo { font-size: 48px; margin-bottom: 20px; }
        .status { padding: 20px; margin: 20px 0; border-radius: 8px; background: #e3f2fd; border-left: 4px solid #2196f3; }
        .progress { width: 100%; height: 8px; background: #f0f0f0; border-radius: 4px; overflow: hidden; margin: 20px 0; }
        .progress-bar { height: 100%; background: linear-gradient(90deg, #4caf50, #2196f3); animation: progress 3s ease-in-out infinite; }
        @keyframes progress { 0% { width: 30%; } 50% { width: 70%; } 100% { width: 90%; } }
        .info { background: #fff3e0; border-left: 4px solid #ff9800; padding: 15px; margin: 15px 0; border-radius: 4px; }
        .btn { display: inline-block; padding: 12px 24px; background: #2196f3; color: white; text-decoration: none; border-radius: 6px; margin: 10px; transition: all 0.3s; }
        .btn:hover { background: #1976d2; transform: translateY(-2px); }
        .time { font-family: monospace; font-size: 14px; color: #666; }
        h1 { color: #333; margin-bottom: 10px; }
        h2 { color: #666; font-weight: normal; margin-bottom: 30px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🎓</div>
        <h1>Moodle Learning Platform</h1>
        <h2>Deployment in Progress</h2>
        
        <div class="status">
            <h3>📦 Installing Moodle Files</h3>
            <div class="progress">
                <div class="progress-bar"></div>
            </div>
            <p>The Moodle application is being deployed to Azure App Service.<br>
            This process typically takes 5-10 minutes for a complete installation.</p>
        </div>

        <div class="info">
            <h3>⏱️ Current Status</h3>
            <p><strong>Site:</strong> moodle-site-0530.azurewebsites.net</p>
            <p><strong>Time:</strong> <span class="time" id="currentTime"><?php echo date('Y-m-d H:i:s T'); ?></span></p>
            <p><strong>Status:</strong> Extracting and configuring files...</p>
        </div>

        <div class="info">
            <h3>🔄 What's Happening</h3>
            <ol style="text-align: left; max-width: 400px; margin: 0 auto;">
                <li>Uploading Moodle core files (✅ Complete)</li>
                <li>Extracting application files (🔄 In Progress)</li>
                <li>Configuring database connection (⏳ Pending)</li>
                <li>Setting up file permissions (⏳ Pending)</li>
                <li>Running Moodle installer (⏳ Pending)</li>
            </ol>
        </div>

        <div class="info">
            <h3>🚀 Next Steps</h3>
            <p>Once deployment completes, you'll be redirected to:</p>
            <ul style="text-align: left; max-width: 400px; margin: 0 auto;">
                <li>Moodle installation wizard</li>
                <li>Database configuration</li>
                <li>Admin account setup</li>
                <li>Site configuration</li>
            </ul>
        </div>

        <a href="/debug.php" class="btn">📊 View Debug Info</a>
        <a href="javascript:location.reload()" class="btn">🔄 Refresh Status</a>
    </div>

    <script>
        // Update time every second
        function updateTime() {
            const now = new Date();
            document.getElementById('currentTime').textContent = now.toLocaleString();
        }
        setInterval(updateTime, 1000);

        // Check for Moodle availability every 10 seconds
        function checkMoodle() {
            fetch('/lib/moodlelib.php', { method: 'HEAD' })
                .then(response => {
                    if (response.status === 200) {
                        // Moodle files are available, reload to trigger redirect
                        window.location.reload();
                    }
                })
                .catch(() => {
                    // Still deploying, continue waiting
                });
        }
        
        setInterval(checkMoodle, 10000);
        
        // Auto-refresh page every 30 seconds as fallback
        setTimeout(() => window.location.reload(), 30000);
    </script>
</body>
</html>
