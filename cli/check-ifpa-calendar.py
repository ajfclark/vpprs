#!/usr/bin/python3

import sys
import argparse
import psycopg2
import datetime
import logging

import config
import ifpa
import vppr

def filterCalendar(calendar, year, state):
    output = []
    for event in calendar:
        if event['state'] == state and event['start_date'][:4] == year:
            output.append(event)
    return output

def getTournamentStr(event):
    return event['start_date'] + ' ' + event['tournament_name'] + ' [' + event['tournament_id'] + ']'

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

logger=logging.getLogger('check-ifpa-calendar')

# Read the config
config = config.readConfig(filename=args['config'])

# Look at the calendar for new events
logger.debug('Query IFPA calendar')
try:
    calendar = ifpa.getCalendar(config['ifpa']['apikey'], 'Australia')
except Exception as e:
    logger.error(type(e))
    logger.error(e.args)
    logger.error(e)
    raise e

logger.debug('Filter IFPA calendar')
calendar = filterCalendar(calendar, state='Vic', year=args['year'])
logger.debug(str(calendar))

# Connect to database
logger.debug('Connect to database')
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()
logger.debug('Get existing tournament IDs')
cursor.execute('SELECT ifpa_id FROM event WHERE ifpa_id is not null')
dbTournamentIds = [tournamentId for row in cursor for tournamentId in row]

# Update the database
for event in calendar:
    if int(event['tournament_id']) not in dbTournamentIds:
        logger.debug("Add to db:" + getTournamentStr(event))
        cursor.execute("INSERT INTO event(date, name, ifpa_id) VALUES (%s, %s, %s) RETURNING id;", (event['end_date'], event['tournament_name'], event['tournament_id']))
    else:
        logger.debug("Already in db:" + getTournamentStr(event))

    if(not debug):
        conn.commit()
    else:
        logger.debug('Debug is enabled, rolling back transaction')
        conn.rollback()

# Close the database
logger.debug('Close database')
cursor.close()
conn.close()
