#!/usr/bin/python3

import sys
from bs4 import BeautifulSoup
import argparse
import psycopg2
import requests
import csv

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
date = data['startLocal']
print(title)
print(date)

# Get player list
apiurl = "https://next.matchplay.events/api/tournaments/" + config['matchplayid'] + "/players/csv"
response = requests.get(apiurl)
lines = list(csv.reader(response.text.splitlines()))
player = {}
for line in lines[1:]:
	player[line[0]] = line[1]
print(player)
sys.exit()

#
soup = BeautifulSoup(htmlPage, 'html.parser') 

# Find the results table
table = soup.find('table', id='tourresults').tbody
rows = table.find_all('tr')

# Pull the results into a list
data = []
for row in rows:
	cells = row.find_all('td')
	place = float(cells[0].contents[0].strip())
	name = cells[1].a.contents[0].strip()
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
cursor.execute("INSERT INTO event(date, name, ifpa_id) VALUES (%s, %s, %s) RETURNING id;", (date, title, config['ifpaid']))
eventid = str(cursor.fetchone()[0])

# Add results to result table
sqlData = []
for player in data:
	sqlData.append([eventid,str(player['placing']),player['name'], vppr(player['placing'], numPlayers)])
cursor.executemany("INSERT INTO result(event_id, place, player, vppr) VALUES (%s, %s, %s, %s);", sqlData)

conn.commit()
cursor.close()
conn.close()
