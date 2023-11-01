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

	$ret = pg_query($db, "Select r.place, r.player, vppr(r.place, p.players) as vppr from result r JOIN (SELECT r2.event_id, count(r2.event_id) as players from result r2 group by r2.event_id) p ON r.event_id = p.event_id Where r.event_id = $id order by place, player asc;");
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
	$ret = pg_query($db, "select id, date, name, ifpa_id, matchplay_q_id, matchplay_f_id from event where extract(year from date) = 2023 order by date desc;");
	if(!$ret) {
		echo pg_last_error($db);
		exit;
	}

	print("<table>\n");
	while($row = pg_fetch_row($ret)) {
		if($row[3]>0)
			$ifpa='<a href="http://ifpapinball.com/tournaments/view.php?t=' . $row[3] . '" target="_blank">ifpa</a>';
		else
			$ifpa='';

		if($row[4]>0)
			$mpq='<a href="https://next.matchplay.events/tournaments/' . $row[4] . '" target="_blank">qualifying</a>';
		else
			$mpq='';

		if($row[5]>0)
			$mpf='<a href="https://next.matchplay.events/tournaments/' . $row[5] . '" target="_blank">finals</a>';
		else
			$mpf='';

		printf("<tr><td>%s</td><td><a href=\"event.php?id=%d\">%s</a></td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $row[1], $row[0], $row[2], $ifpa, $mpq, $mpf);
	}
	print("</table>\n");
}
pg_close($db);
include "footer.php";
?>
