<?php
include "header.php";
include "config.php";

$db = pg_connect($dbConnect);
if(!$db) {
	echo pg_last_error($db);
	exit;
}

$ret = pg_query($db, "select player, events, wins, average, vpprs from standings order by vpprs desc limit 32;");
if(!$ret) {
	echo pg_last_error($db);
	exit;
}

print("<table>\n");
print('<tr><th>Rank</th><th>Player</th><th>Events</th><th>Wins</th><th>Average</th><th>VPPRs<th></th>');
$i = 0;
while($row = pg_fetch_row($ret)) {
	$i++;
	printf('<tr><td>%d</td><td>%s</td><td>%d</td><td>%d</td><td>%0.1f</td><td>%0.1f<td></tr>', $i, $row[0], $row[1], $row[2], $row[3], $row[4]);
}
print("</table>\n");
pg_close($db);

include "footer.php";
?>
