#!/usr/bin/python3

import sys
import argparse
import psycopg2
import json

import config
import matchplay
import vppr

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
        if float(entry['position']) < cut: # If a player was above the cut
            # find their entry in the finals
            finalist = list(filter(lambda finalist: finalist['playerId'] == entry['playerId'], finals))
            if len(finalist) == 0: # They weren't in the finals, assume they missed the cut in a playoff
                entry['position'] = cut
            else: # Otherwise, update the entry with the placing from the finals
                entry['position'] = finalist[0]['position']

sorted_list = sorted(data, key=lambda place: place['position'])
data = sorted_list

# Find entries where multiple players have the same placing, replace with the average of the order in the list
i = 0
numPlayers = len(data)
while i < numPlayers:
	matches = [ i ]
	for k in range(i + 1, numPlayers):
		if(data[i]['position'] == data[k]['position']):
			matches.append(k)
	if(len(matches) > 1):
		total = 0
		for k in range(len(matches)):
			total = total + int(matches[k]) + 1
		average = total / len(matches)
		for k in range(len(matches)):
			data[matches[k]]['position'] = average
	i = i + len(matches)

# Sort the list
sorted_list = sorted(data, key=lambda place: place['position'])

# PlayerList
matchPlayPlayers = matchplay.getPlayers(args['qualifyingid'])

# Connect to database
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()

players = {}
# Build the id mapping
for matchPlayId, playerName in matchPlayPlayers.items():
    vpprPlayerId = vppr.getPlayerId(cursor, playerName)
    if vpprPlayerId == None:
        vpprPlayerId = vppr.addPlayer(cursor, playerName)
    players[matchPlayId] = { 'id': vpprPlayerId, 'name': playerName }

# Output data
print(date + ":" + title)
for player in sorted_list:
    print(str(player['position']) + "\t" + players[player['playerId']]['name'])

# Update the database
cursor.execute("INSERT INTO event(date, name, matchplay_q_id, matchplay_f_id) VALUES (%s, %s, %s, %s) RETURNING id;",
    (date, title, args['qualifyingid'], args['finalsid']))
eventId = int(cursor.fetchone()[0])

# Add results to result table
sqlData = []
for player in data:
    sqlData.append([eventId,float(player['position']),players[player['playerId']]['id']])
cursor.executemany("INSERT INTO result(event_id, place, player_id) VALUES (%s, %s, %s);", sqlData)

if(not debug):
    conn.commit()
else:
    conn.rollback()

# Close the database
cursor.close()
conn.close()
