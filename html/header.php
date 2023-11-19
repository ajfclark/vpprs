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
print("<div><h1>Victorian State Championship $year (VFPA)</h1></div>\n");

print("<div>\n");
for ($i = $maxYear; $i >= 2021; $i--) {
	if($i == $year) {
		print("<strong>$i</strong> ");
	}
	else {
		print("<a href=\"standings.php?year=$i\">$i</a> ");
	}
}
print("</div>\n");

$pages = [
	"/standings.php" => "Standings",
	"/event.php" => "Events"
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

?>
<hr>
