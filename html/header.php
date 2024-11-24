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
print("<link rel=\"stylesheet\" href=\"https://cdn.simplecss.org/simple.min.css\">\n");
print("</head>\n");

print("<body>\n");
print("<header>\n");
print("<div><h2>Victorian State Pinball Championship $year (VFPA)</h2></div>\n");
print("<nav>\n");
for ($i = $maxYear; $i >= 2021; $i--) {
	print("<a ");
	if($i == $year) {
		print("aria-current=\"page\" ");
	}
	print("href=\"" . $_SERVER['PHP_SELF'] . "?year=$i\">$i</a>\n");
}
print("</nav>\n");


$pages = [
	"/standings.php" => "Standings",
	"/event.php" => "Events",
	"/player.php" => "Players",
	"/mdstandings.php" => "Moon Dog",
];
print("<nav>");
foreach ($pages as $page => $heading) {
	print("<a ");
	if($_SERVER['PHP_SELF'] == $page) {
		print("aria-current=\"page\" ");
	}
	print("href=\"$page?year=$year\">$heading</a>\n");
}
print("</nav>\n");
print("</header>\n");

?>
<hr>
