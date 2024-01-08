<?php
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
	$row = pg_fetch_row($ret);
	$title = $row[0] . ": " . $row[1];
	include "header.php";
	printf("<h3>Results for %s: %s</h3>", $row[0], $row[1]);

	$ret = pg_query($db, "Select r.place, p.id, p.name, vppr(r.place, x.players) as vppr
from
        event e JOIN
        result r ON (e.id = r.event_id)
        JOIN event_ext x ON (r.event_id = x.id)
        JOIN player p ON (r.player_id = p.id)
Where r.event_id = $id order by place, p.name asc;");

	if(!$ret) {
		echo pg_last_error($db);
		exit;
	}

	print("<table>\n");
	printf("<tr><th>Place</th><th>Player</th><th>VPPRs</th></tr>\n");
	while($row = pg_fetch_row($ret)) {
		printf("<tr><td align=\"right\">%0.1f</td><td><a href=\"player.php?year=$year&id=%d\">%s</a></td><td align=\"right\">%0.2f</td></tr>", $row[0], $row[1], $row[2], $row[3]);
	}
	print("</table>\n");
	print("<hr>\n");
	print("<a href=\"event.php?year=$year\">Back to $year Event List</a>\n");
}
else {
	$title = "Event List";
	include "header.php";
	$ret = pg_query($db, "select id, date, name, ifpa_id, matchplay_q_id, matchplay_f_id from event where date >= '$year-01-01' and date <= '$year-12-31' and ignored=False order by date desc;");
	if(!$ret) {
		echo pg_last_error($db);
		exit;
	}

	print("<table>\n");
	printf("<tr><th>Date</th><th>Event</th><th>IFPA</th><th colspan=\"2\">Match Play</th></tr>\n");
	while($row = pg_fetch_row($ret)) {
		if($row[3]>0)
			$ifpa='<a href="http://ifpapinball.com/tournaments/view.php?t=' . $row[3] . '" target="_blank">Results</a>';
		else
			$ifpa='';

		if($row[4]>0)
			$mpq='<a href="https://next.matchplay.events/tournaments/' . $row[4] . '" target="_blank">Qualifying</a>';
		else
			$mpq='';

		if($row[5]>0)
			$mpf='<a href="https://next.matchplay.events/tournaments/' . $row[5] . '" target="_blank">Finals</a>';
		else
			$mpf='';

		printf("<tr><td>%s</td><td><a href=\"event.php?year=$year&id=%d\">%s</a></td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $row[1], $row[0], $row[2], $ifpa, $mpq, $mpf);
	}
	print("</table>\n");
}
pg_close($db);
include "footer.php";
?>
