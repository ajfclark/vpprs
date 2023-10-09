#!/usr/bin/python3

import sys
from bs4 import BeautifulSoup
import argparse
import psycopg2
import requests
import csv
import json

def vppr(place: float, numPlayers: int) -> float:
	if(place == 1.0):
		return str(50)
	else:
		return str(((int(numPlayers) - float(place) + 1) / numPlayers)**2 * 45 + 1)

parser = argparse.ArgumentParser(description='Script to fetch tournament results and dump a CSV',
	formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-i', '--matchplayid', required=True)
parser.add_argument('-u', '--dbuser', required=True)
parser.add_argument('-p', '--dbpassword', required=True)
parser.add_argument('-H', '--dbhost', default='localhost')
parser.add_argument('-d', '--dbname', default='vppr')
args = parser.parse_args()
config = vars(args)

# Fetch the tournament details from the Matchplay site
apiurl = "https://next.matchplay.events/api/tournaments/" + config['matchplayid']
response = requests.get(apiurl)
data = response.json()['data']

# Find the event name
title = data['name']

# Find the date
date = data['startLocal'][0:10]

# Get player list
apiurl = "https://next.matchplay.events/api/tournaments/" + config['matchplayid'] + "/players/csv"
response = requests.get(apiurl)
lines = list(csv.reader(response.text.splitlines()))
player = {}
for line in lines:
	player[line[0]] = line[1]
player['244600']='David Leeds'

# Get the tournament standings
apiurl = "https://next.matchplay.events/api/tournaments/" + config['matchplayid'] + "/standings"
response = requests.get(apiurl)
rows = response.json()
#print(json.dumps(rows, indent=2))
data = []
for row in rows:
	#print(json.dumps(row, indent=2))
	place = row['position']
	playerId = row['playerId']
	name = player[str(playerId)]
	data.append({ 'placing': place, 'name': name })

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

# Connect to database
conn = psycopg2.connect(database=config['dbname'], host=config['dbhost'], user=config['dbuser'], password=config['dbpassword'])
cursor = conn.cursor()

# Add event to event table
print(date + ":" + title)
cursor.execute("INSERT INTO event(date, name, matchplay_q_id) VALUES (%s, %s, %s) RETURNING id;", (date, title, config['matchplayid']))
eventid = str(cursor.fetchone()[0])

# Add results to result table
sqlData = []
for player in data:
	sqlData.append([eventid,str(player['placing']),player['name'], vppr(player['placing'], numPlayers)])
cursor.executemany("INSERT INTO result(event_id, place, player, vppr) VALUES (%s, %s, %s, %s);", sqlData)

conn.commit()
cursor.close()
conn.close()
