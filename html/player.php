<?php
$title = "Player List";
include "header.php";
include "config.php";

$db = pg_connect($dbConnect);
if(!$db) {
	echo pg_last_error($db);
	exit;
}

if(isset($_GET['id'])) {
	$id = intval(htmlspecialchars($_GET['id']));
	$ret = pg_query($db, "select e.date, e.name, r.place, vppr(r.place, x.players), e.ignored
from result r join
event e on (r.event_id = e.id) join
event_ext x on (r.event_id = x.id)
where
player_id=$id  AND x.year=$year order by date;");

	if(!$ret) {
		echo pg_last_error($db);
		exit;
	}

	print("<table>\n");
	printf("<tr><th>Date</th><th>Event</th><th>Place</th><th>VPPR</th><th>Ignored</th></tr>", $row[0], $row[1], $row[2], $row[3], $row[4]);
	while($row = pg_fetch_row($ret)) {
		printf("<tr><td>%s</td><td>%s</td><td>%0.1f</td><td>%0.2f</td><td>%s</td></tr>", $row[0], $row[1], $row[2], $row[3], $row[4]);
	}
	print("</table>\n");
}
else {
	$ret = pg_query($db, "select distinct p.id, name, ifpa_id
from
player p JOIN
result r ON (p.id = r.player_id) JOIN
event_ext x on (r.event_id = x.id)
where
x.year=$year
order by name;");

	if(!$ret) {
		echo pg_last_error($db);
		exit;
	}

	print("<table>\n");
	while($row = pg_fetch_row($ret)) {
		if($row[2]>0)
			$ifpa='<a href="http://ifpapinball.com/player.php?p=' . $row[2] . '" target="_blank">ifpa</a>';
		else
			$ifpa='';

		printf("<tr><td><a href=\"player.php?id=%d&year=$year\">%s</a></td><td>%s</td></tr>\n", $row[0], $row[1], $ifpa);
	}
	print("</table>\n");
}
pg_close($db);
include "footer.php";
?>
