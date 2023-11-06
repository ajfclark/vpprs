#!/usr/bin/python3

import sys
import argparse
import psycopg2
import json

import config
import matchplay

parser = argparse.ArgumentParser(description='Script to fetch tournament results and dump a CSV',
	formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-q', '--qualifyingid', required=True)
parser.add_argument('-f', '--finalsid', default=0)
parser.add_argument('-c', '--config', default='config.ini')
parser.add_argument('-d', '--debug', action='store_true')
args = parser.parse_args()
args = vars(args)

debug = args['debug']

# Read the config
config = config.readConfig(filename=args['config'])

# Fetch the tournament details from the Matchplay site
data = matchplay.getTournament(args['qualifyingid'])

# Find the event name
title = data['name']

# Find the date
date = data['startLocal'][0:10]

# Get the tournament standings
data = matchplay.getStandings(args['qualifyingid'])
if args['finalsid']: # If there's a finals ID passed
    finals = matchplay.getStandings(args['finalsid']) # Get the finals standings
    cut = len(finals) + 1 # Based on the player count in finals, calculate where the cut line was
    for entry in data:
        if float(entry['placing']) < cut: # If a player was above the cut
            # find their entry in the finals
            finalist = list(filter(lambda finalist: finalist['name'] == entry['name'], finals))
            if len(finalist) == 0: # They weren't in the finals, assume they missed the cut in a playoff
                entry['placing'] = cut
            else: # Otherwise, update the entry with the placing from the finals
                entry['placing'] = finalist[0]['placing']

sorted_list = sorted(data, key=lambda place: place['placing'])
data = sorted_list

# Find entries where multiple players have the same placing, replace with the average of the order in the list
i = 0
numPlayers = len(data)
while i < numPlayers:
	matches = [ i ]
	for k in range(i + 1, numPlayers):
		if(data[i]['placing'] == data[k]['placing']):
			matches.append(k)
	if(len(matches) > 1):
		total = 0
		for k in range(len(matches)):
			total = total + int(matches[k]) + 1
		average = total / len(matches)
		for k in range(len(matches)):
			data[matches[k]]['placing'] = average
	i = i + len(matches)

# Sort the list
sorted_list = sorted(data, key=lambda place: place['placing'])

# Output data
print(date + ":" + title)
for player in sorted_list:
    print(player)

# Connect to database
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()

# Update the database
cursor.execute("INSERT INTO event(date, name, matchplay_q_id, matchplay_f_id) VALUES (%s, %s, %s, %s) RETURNING id;",
    (date, title, args['qualifyingid'], args['finalsid']))
eventId = str(cursor.fetchone()[0])
# Add results to result table
sqlData = []
for player in data:
    sqlData.append([eventId,str(player['placing']),player['name']])
cursor.executemany("INSERT INTO result(event_id, place, player) VALUES (%s, %s, %s);", sqlData)

if(not debug):
    conn.commit()
else:
    print(sqlData)
    conn.rollback()

# Close the database
cursor.close()
conn.close()
