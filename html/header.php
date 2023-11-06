<?php
if(isset($_GET['year'])) {
	$year = intval(htmlspecialchars($_GET['year']));
	if ($year > 2023 or $year < 2021) {
		$year = 2023;
	}
}
else {
	$year = 2023;
}
print("<html>
<html>
<head>
<title>$year VPPR</title>
</head>
<body>
<h1>$year VPPRs</h1>");
print("<table>");
for($i = 2023; $i > 2020 ; $i--) {
	print("<tr>");
	print("<td>$i:</td>");
	print("<td><a href=\"standings.php?year=$i\">Top 32</a></td>");
	print("<td><a href=\"standings.php?year=$i&full\">Full Standings</a></td>");
	print("<td><a href=\"event.php?year=$i\">Event List</a></td>");
	print("</tr>");
}
print("</table>");
print("<hr>");
?>
