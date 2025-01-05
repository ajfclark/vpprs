<html>
<html>
<head>
<?php
$maxYear = date("Y");
if(isset($_GET['year'])) {
	$year = intval(htmlspecialchars($_GET['year']));
	if ($year > $maxYear or $year < 2021) {
		$year = $maxYear;
	}
}
else {
	$year = $maxYear;
}
$title="$year VPPRs $title";
print("<title>$title</title>\n");
print("</head>\n");

print("<body>\n");

print("<div>\n");
for ($i = $maxYear; $i >= 2021; $i--) {
	if($i == $year) {
		print("<strong>$i</strong> ");
	}
	else {
		print("<a href=\"" . $_SERVER['PHP_SELF'] . "?year=$i\">$i</a> ");
	}
}
print("</div>\n");

$pages = [
	"/standings.php" => "Standings",
	"/event.php" => "Events",
	"/player.php" => "Players",
	"/mdstandings.php" => "Moon Dog",
];
print("<div>");
foreach ($pages as $page => $heading) {
	if($_SERVER['PHP_SELF'] == $page) {
		print("<b>$heading</b> ");
	}
	else {
		print("<a href=\"$page?year=$year\">$heading</a> ");
	}
}
print("</div>\n");

print("<div><h2>Victorian State Pinball Championship $year (VFPA)</h2></div>\n");
?>
<hr>
