#!/usr/bin/python3

import sys
import argparse
import psycopg2
import datetime
import requests

import config
import ifpa
import vppr

def debugPrint(string):
    if debug:
        print(string)

def getTournamentStr(entry):
    return entry['start_date'] + ' ' + entry['tournament_name'] + ' [' + entry['tournament_id'] + ']'

def getPlayerData(results):
    data = []
    for result in tournament['results']:
        place = float(result['position'])
        name = result['first_name'].strip() + ' ' + result['last_name'].strip()
        data.append({ 'placing': place, 'name': name, 'ifpa_id': result['player_id'] })

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

    return data

parser = argparse.ArgumentParser(description='Script to fetch tournament', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-d', '--debug', action='store_true')
parser.add_argument('-c', '--config', default='config.ini')
parser.add_argument('-y', '--year', default=str(datetime.date.today().year))
parser.add_argument('-t', '--tournamentid')
args = parser.parse_args()
args = vars(args)

debug = args['debug']

# Read the config
config = config.readConfig(filename=args['config'])

# Connect to database
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()

# Get ifpa ids of tournaments that already have results
cursor.execute('select e.ifpa_id from event e where e.id in (select distinct event_id from result);')
existingTournamentIds = [ tournamentId for row in cursor for tournamentId in row ]

if(args['tournamentid']):
    # Either take the tournamentid from the commandline
    tournamentIds = [ int(args['tournamentid']) ]
else:
    # or load the list of events with no results from the DB
    cursor.execute('select e.ifpa_id from event e where e.id not in (select distinct event_id from result);')
    tournamentIds = [ tournamentId for row in cursor for tournamentId in row ]

# For each tournament to update
for tournamentId in tournamentIds:
    if tournamentId in existingTournamentIds:
        print('Results already exist for ' + str(tournamentId))
        continue

    # Retreive new data
    tournament = ifpa.getTournamentResults(config['ifpa']['apikey'], tournamentId)
    if tournament == None:
        debugPrint('No results for ' + str(tournamentId))
        continue

    debugPrint(tournament['event_date'] + ":" + tournament['tournament_name'])

    # Process the standings
    tempData = getPlayerData(tournament['results'])

    data = []
    # Build the id mapping
    for player in tempData:
        ifpaId = player['ifpa_id']
        playerName = player['name']
        vpprId = vppr.getPlayerId(cursor, ifpaId)
        if vpprId == None:
            vpprId = vppr.addPlayer(cursor, playerName, ifpaId)
        obj = { 'placing': player['placing'], 'name': player['name'], 'ifpa_id': player['ifpa_id'], 'vppr_id': vpprId }
        debugPrint(obj)
        data.append(obj)

    # Update the database
    cursor.execute("SELECT id FROM event WHERE ifpa_id=%s" % (tournamentId))
    eventId = cursor.fetchone()[0]
    # Add results to result table
    sqlData = []
    for player in data:
        obj = [eventId,player['placing'],player['vppr_id']]
        sqlData.append(obj)
        debugPrint(obj)
    cursor.executemany("INSERT INTO result(event_id, place, player_id) VALUES (%s, %s, %s);", sqlData)


    if(not debug):
        conn.commit()
    else:
        conn.rollback()

# Close the database
cursor.close()
conn.close()