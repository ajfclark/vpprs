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

	$ret = pg_query($db, "SELECT name, ifpa_id FROM player WHERE id=$id;");
	if(!$ret) {
		echo pg_last_error($db);
		exit;
	}

	$row = pg_fetch_row($ret);
	printf("<h3>%s</h3>\n", $row[0]);
	print("<table>\n");
	printf("<tr><td>VFPA ID</td><td>%d</td></tr>\n", $id);
	if($row[1] != "") {
		printf("<tr><td>IFPA ID</td><td><a href=\"https://www.ifpapinball.com/player.php?p=%s\" target=\"_blank\">%s</a></td></tr>\n",
			$row[1], $row[1]);
	}

	$ret = pg_query($db, "select e.date, e.id, e.name, r.place, vppr(r.place, x.players), e.ignored from result r join event e on (r.event_id = e.id) join event_ext x on (r.event_id = x.id) where player_id=$id AND x.year=$year AND e.ignored is False order by vppr desc, date desc;");

	if(!$ret) {
		echo pg_last_error($db);
		exit;
	}

	print("<table>\n");
	printf("<tr><th>Date</th><th>Event</th><th>Place</th><th>VPPR</th></tr>\n");
	while($row = pg_fetch_row($ret)) {
		printf("<tr><td>%s</td><td><a href=\"event.php?year=$year&id=%d\">%s</a></td><td align=\"right\">%0.1f</td><td align=\"right\">%0.2f</td></tr>\n", $row[0], $row[1], $row[2], $row[3], $row[4]);
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
