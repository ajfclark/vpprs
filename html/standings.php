<?php
include "header.php";
include "config.php";

$db = pg_connect($dbConnect);
if(!$db) {
	echo pg_last_error($db);
	exit;
}

$query = "select player, events, wins, average, vpprs from standings where year='$year' order by vpprs desc";
if(isset($_GET['full'])) {
    $query = $query . ';';
	$heading = 'Full Standings';
}
else {
    $query = $query . ' limit 32'; 
	$heading = 'Top 32';
}

$ret = pg_query($db, $query);
if(!$ret) {
    echo pg_last_error($db);
    exit;
}
print("<h3>$heading</h3>");
print("<table>\n");
print('<tr><th>Rank</th><th>Player</th><th>Events</th><th>Wins</th><th>Average</th><th>VPPRs<th></th>');
$i = 0;
while($row = pg_fetch_row($ret)) {
	$i++;
	printf('<tr><td>%d</td><td>%s</td><td>%d</td><td>%d</td><td>%0.2f</td><td>%0.2f<td></tr>', $i, $row[0], $row[1], $row[2], $row[3], $row[4]);
}
print("</table>\n");
pg_close($db);

include "footer.php";
?>
