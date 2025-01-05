<?php
$title = 'Standings';
include "header.php";
include "config.php";

$db = pg_connect($dbConnect);
if(!$db) {
	echo pg_last_error($db);
	exit;
}

$query = "select playerId, player, events, wins, average, vpprs from standings where year='$year' order by vpprs desc";
$query = $query . ';';

$ret = pg_query($db, $query);
if(!$ret) {
    echo pg_last_error($db);
    exit;
}
print("<table>\n");
print("<tr><th>Rank</th><th>Player</th><th>Events</th><th>Wins</th><th>Average</th><th>VPPRs</th>\n");
$i = 0;
while($row = pg_fetch_row($ret)) {
	$i++;
	printf("<tr><td align=\"right\">%d</td><td><a href=\"player.php?year=$year&id=%d\">%s</a></td><td align=\"right\">%d</td><td align=\"right\">%d</td><td align=\"right\">%0.2f</td><td align=\"right\">%0.2f</td></tr>\n", $i, $row[0], $row[1], $row[2], $row[3], $row[4], $row[5]);
	if($i == 32) {
		print("<tr><td colspan=\"6\"><hr></td></tr>\n");
	}
}
print("</table>\n");
pg_close($db);

include "footer.php";
?>
