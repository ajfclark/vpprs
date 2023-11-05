#!/usr/bin/python3

import sys
import argparse
import psycopg2
import requests
import csv
import json

import config

parser = argparse.ArgumentParser(description='Script to fetch tournament results and dump a CSV',
	formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-q', '--qualifyingid', required=True)
parser.add_argument('-f', '--finalsid', default='NA')
parser.add_argument('-c', '--config', default='config.ini')
parser.add_argument('-d', '--debug', action='store_true')
args = parser.parse_args()
args = vars(args)

debug = args['debug']

# Read the config
config = config.readConfig(filename=args['config'])

# Fetch the tournament details from the Matchplay site
apiurl = "https://next.matchplay.events/api/tournaments/" + args['qualifyingid']
response = requests.get(apiurl)
data = response.json()['data']

# Find the event name
title = data['name']

# Find the date
date = data['startLocal'][0:10]

# Get player list
apiurl = "https://next.matchplay.events/api/tournaments/" + args['qualifyingid'] + "/players/csv"
response = requests.get(apiurl)
lines = list(csv.reader(response.text.splitlines()))
player = {}
for line in lines:
	player[line[0]] = line[1]
player['244600']='David Leeds'

# Get the tournament standings
apiurl = "https://next.matchplay.events/api/tournaments/" + args['qualifyingid'] + "/standings"
response = requests.get(apiurl)
rows = response.json()
data = []
for row in rows:
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

# Output data
print(date + ":" + title)
for player in data:
	print(player)
