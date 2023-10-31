<?php
include "header.php";
include "config.php";

$db = pg_connect($dbConnect);
if(!$db) {
	echo pg_last_error($db);
	exit;
}

if(isset($_GET['id'])) {
	$id = intval(htmlspecialchars($_GET['id']));
	$ret = pg_query($db, "select date, name FROM event where id = $id;");
	if(!$ret) {
		echo pg_last_error($db);
		exit;
	}
	while($row = pg_fetch_row($ret)) {
		printf("<h3>%s: %s</h3>", $row[0], $row[1]);
	}

	$ret = pg_query($db, "select place, player, vppr(place, players) as vppr  from result r, event_players p where r.event_id = $id and p.id = r.event_id;");
	if(!$ret) {
		echo pg_last_error($db);
		exit;
	}

	print("<table>\n");
	while($row = pg_fetch_row($ret)) {
		printf('<tr><td>%0.1f</td><td>%s</td><td>%0.2f</td></tr>', $row[0], $row[1], $row[2]);
	}
	print("</table>\n");
}
else {
	print("<h3>Events</h3>");
	$ret = pg_query($db, "select id, date, name, ifpa_id from event where extract(year from date) = 2023 order by date desc;");
	if(!$ret) {
		echo pg_last_error($db);
		exit;
	}

	print("<table>\n");
	while($row = pg_fetch_row($ret)) {
		if($row[3]>0) {
			printf('<tr><td>%s</td><td><a href="event.php?id=%d">%s</a></td><td><a href="http://ifpapinball.com/tournaments/view.php?t=%d" target="_blank">ifpa</td></tr>', $row[1], $row[0], $row[2], $row[3]);
		}
		else {
			printf('<tr><td>%s</td><td><a href="event.php?id=%d">%s</a></td><td>no ifpa id</td></tr>', $row[1], $row[0], $row[2]);
		}
	}
	print("</table>\n");
}
pg_close($db);
include "footer.php";
?>
