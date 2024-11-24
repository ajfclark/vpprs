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
?>
<link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
</head>
<body>
<header>
<h3>Victorian State Pinball Championship <?php print($year); ?></h3>
<nav>
<?php
for ($i = $maxYear; $i >= 2021; $i--) {
	if($i == $year) {
		print("<a aria-current=\"page\" href=\"#\">$i</a>");
	}
	else {
		print("<a href=\"" . $_SERVER['PHP_SELF'] . "?year=$i\">$i</a>");
	}
}
?>
</nav>
<nav>
<?php
$pages = [
	"/standings.php" => "Standings",
	"/event.php" => "Events",
	"/player.php" => "Players",
	"/mdstandings.php" => "Moon Dog",
];
foreach ($pages as $page => $heading) {
	if($_SERVER['PHP_SELF'] == $page) {
		print("<a aria-current=\"page\" href=\"#\">$heading</a>");
	}
	else {
		print("<a href=\"$page?year=$year\">$heading</a>");
	}
}
?>
</nav>
</header>
