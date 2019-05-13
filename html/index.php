<!DOCTYPE html>
<html>
<body>
<h1>Open Source Mathematics Textbooks at The University of Nebraska - Lincoln</h1>
<?php
$dir = ".";

// Sort in ascending order - this is default
$a = scandir($dir);

foreach($a as $title){
echo "<h2>".$title."</h2>";
}


?>

</body>
</html>