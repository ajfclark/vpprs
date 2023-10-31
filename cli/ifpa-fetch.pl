#!/usr/bin/python3

import sys
import httplib2
from bs4 import BeautifulSoup
import argparse
import psycopg2
from configparser import ConfigParser

def readDbConfig(filename='database.ini', section='postgresql'):
    # create a parser
    parser = ConfigParser()
    # read config file
    parser.read(filename)

    # get section, default to postgresql
    db = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
    else:
        raise Exception('Section {0} not found in the {1} file'.format(section, filename))

    return db

def vppr(place: float, numPlayers: int) -> float:
	if(place == 1.0):
		return str(50)
	else:
		return str(((int(numPlayers) - float(place) + 1) / numPlayers)**2 * 45 + 1)

parser = argparse.ArgumentParser(description='Script to fetch tournament results and insert into the database',
	formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-i', '--ifpaid', required=True)
parser.add_argument('-d', '--debug', action='store_true')
parser.add_argument('-c', '--dbconfig', default='database.ini')
args = parser.parse_args()
params = vars(args)

# Read the DB config
ifpaId = params['ifpaid']
debug = params['debug']
dbConfig = readDbConfig(filename=params['dbconfig'])

# Fetch the results from the IFPA site
http = httplib2.Http()
status, htmlPage = http.request('http://www.ifpapinball.com/tournaments/view.php?t=' + ifpaId)
if(int(status['status']) != 200):
	print(status)
	sys.exit()

# Parse the result into bs4
soup = BeautifulSoup(htmlPage, 'html.parser') 

# Find the event name
title = soup.find('div', id='inner').find('table').tr.td.h1.contents[0].strip()

# Find the date
date = soup.find('select', id='select_date').find('option', selected=True)['value']

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

# Add event to event table
print(date + ":" + title)
for player in data:
	print(player)

if (not debug):
	# Connect to database
	conn = psycopg2.connect(**dbConfig)
	cursor = conn.cursor()

	cursor.execute("INSERT INTO event(date, name, ifpa_id) VALUES (%s, %s, %s) RETURNING id;", (date, title, ifpaId))
	eventId = str(cursor.fetchone()[0])

	# Add results to result table
	sqlData = []
	for player in data:
		sqlData.append([eventId,str(player['placing']),player['name']])
	cursor.executemany("INSERT INTO result(event_id, place, player) VALUES (%s, %s, %s);", sqlData)

	conn.commit()
	cursor.close()
	conn.close()
