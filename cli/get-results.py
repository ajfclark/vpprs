#!/usr/bin/python3

import sys
import argparse
import psycopg2
import datetime
import requests
import logging

import config
import ifpa
import vppr

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
parser.add_argument('-c', '--config', default='../config.ini')
parser.add_argument('-t', '--tournamentid')
args = parser.parse_args()
args = vars(args)

debug = args['debug']

if debug:
    logging.basicConfig(level=logging.DEBUG)
    #logging.getLogger("urllib3").setLevel(logging.INFO)
else:
    logging.basicConfig(level=logging.INFO)

logger=logging.getLogger('get-results')

# Read the config
config = config.readConfig(filename=args['config'])

# Connect to database
logger.debug('Connect to database')
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()

# Get ifpa ids of tournaments that already have results
logger.debug('Get existing tournament IDs')
cursor.execute('select e.ifpa_id from event e where e.id in (select distinct event_id from result);')
existingTournamentIds = [ tournamentId for row in cursor for tournamentId in row ]

if(args['tournamentid']):
    # Either take the tournamentid from the commandline
    logger.debug('Tournament ID on commandline')
    tournamentIds = [ int(args['tournamentid']) ]
else:
    # or load the list of events with no results from the DB
    logger.debug('Get tournemnet IDs without results')
    cursor.execute('select e.ifpa_id from event e where e.id not in (select distinct event_id from result);')
    tournamentIds = [ tournamentId for row in cursor for tournamentId in row ]

# For each tournament to update
for tournamentId in tournamentIds:
    if tournamentId in existingTournamentIds:
        logger.error('Results already exist for ' + str(tournamentId))
        continue

    # Retrieve new data
    logger.debug('Get results for ' + str(tournamentId))
    tournament = ifpa.getTournamentResults(config['ifpa']['apikey'], tournamentId)
    if tournament == None:
        logger.debug('No results for ' + str(tournamentId))
        continue

    logger.debug(tournament['event_date'] + ":" + tournament['tournament_name'])

    # Process the standings
    tempData = getPlayerData(tournament['results'])

    data = []
    # Build the id mapping
    for player in tempData:
        ifpaId = player['ifpa_id']
        playerName = player['name']
        vpprId = vppr.getPlayerId(cursor, ifpaId)
        if vpprId == None:
            logger.debug('Adding new player' + playerName)
            vpprId = vppr.addPlayer(cursor, playerName, ifpaId)
        obj = { 'placing': player['placing'], 'name': player['name'], 'ifpa_id': player['ifpa_id'], 'vppr_id': vpprId }
        logging.debug(obj)
        data.append(obj)

    # Update the database
    cursor.execute("SELECT id FROM event WHERE ifpa_id=%s" % (tournamentId))
    eventId = cursor.fetchone()[0]
    # Add results to result table
    sqlData = []
    for player in data:
        obj = [eventId,player['placing'],player['vppr_id']]
        sqlData.append(obj)
        logging.debug(obj)
    cursor.executemany("INSERT INTO result(event_id, place, player_id) VALUES (%s, %s, %s);", sqlData)

    if(not debug):
        conn.commit()
    else:
        logging.debug('Debug enabled, rolling back')
        conn.rollback()

# Close the database
logger.debug('Closing database')
cursor.close()
conn.close()
