#!/usr/bin/python3

import httplib2
from bs4 import BeautifulSoup
import argparse

def vppr(place: float, numPlayers: int) -> float:
	if(place == 1.0):
		return 50
	else:
		return ((int(numPlayers) - float(place) + 1) / numPlayers)**2 * 45 + 1

parser = argparse.ArgumentParser(description='Script to fetch tournament results and dump a CSV',
	formatter_class=argparse.ArgumentDefaultsHelpFormatter)
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('-t', '--tournament')
group.add_argument('-f', '--file')
args = parser.parse_args()
config = vars(args)

if(config['tournament']):
	http = httplib2.Http()
	status, htmlPage = http.request('http://www.ifpapinball.com/tournaments/view.php?t=' + config['tournament'])
if(config['file']):
	f = open(config['file'])
	htmlPage = f.read()

soup = BeautifulSoup(htmlPage, 'html.parser') 

# Find the event name
title = soup.find('div', id='inner').find('table').tr.td.h1.contents[0].strip()

# Find the data
date = soup.find('select', id='select_date').option['value']

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

# Add event to event table
print(title)
eventid = 1

# Add results to result table
for player in data:
	print(str(eventid) + "\t" + str(player['placing']) + "\t" + player['name'] + "\t" + str(vppr(player['placing'], numPlayers)))
