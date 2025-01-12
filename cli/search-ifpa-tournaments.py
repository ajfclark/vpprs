#!/usr/bin/python3

import sys
import argparse
import psycopg2
import datetime
import logging
import json

import config
import ifpa
import vppr

def getTournamentStr(event):
    return event['event_start_date'] + ' ' + event['tournament_name'] + ' [' + event['tournament_id'] + ']'

parser = argparse.ArgumentParser(description='Script to fetch tournament', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-d', '--debug', action='store_true')
parser.add_argument('-c', '--config', default='../config.ini')
parser.add_argument('-y', '--year', default=str(datetime.date.today().year))
args = parser.parse_args()
args = vars(args)

debug = args['debug']

if debug:
    logging.basicConfig(level=logging.DEBUG)
    #logging.getLogger("urllib3").setLevel(logging.INFO)
else:
    logging.basicConfig(level=logging.INFO)

logger=logging.getLogger('check-ifpa-tournaments')

# Read the config
config = config.readConfig(filename=args['config'])

# Search for new tournaments
logger.debug('Query IFPA for tournaments')
try:
    tournaments = ifpa.searchTournaments(config['ifpa']['apikey'], country='Australia', state='VIC', year=args['year'])
except Exception as e:
    logger.error(type(e))
    logger.error(e.args)
    logger.error(e)
    raise e
logger.debug(json.dumps(tournaments))

# Connect to database
logger.debug('Connect to database')
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()
logger.debug('Get existing tournament IDs')
cursor.execute('SELECT ifpa_id FROM event WHERE ifpa_id is not null')
dbTournamentIds = [tournamentId for row in cursor for tournamentId in row]

# Update the database
for tournament in tournaments:
    if int(tournament['tournament_id']) not in dbTournamentIds:
        logger.debug("Add to db:" + getTournamentStr(tournament))
        cursor.execute("INSERT INTO event(date, name, ifpa_id) VALUES (%s, %s, %s) RETURNING id;", (tournament['event_end_date'], tournament['tournament_name'], tournament['tournament_id']))
    else:
        logger.debug("Already in db:" + getTournamentStr(tournament))

if(not debug):
    conn.commit()
else:
    logger.debug('Debug is enabled, rolling back transaction')
    conn.rollback()

# Close the database
logger.debug('Close database')
cursor.close()
conn.close()
