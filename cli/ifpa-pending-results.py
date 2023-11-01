#!/usr/bin/python3

import sys
import argparse
import psycopg2
import datetime

import config
import ifpa

def filterCalendar(calendar, year, state):
    output = []
    for entry in calendar:
        if entry['state'] == state and entry['start_date'][:4] == year:
            if entry['results_status'] == 'Submitted':
                output.append(entry)
            else:
                print('No results yet for ' + getTournamentStr(entry))

    return output

def getTournamentStr(entry):
    return entry['start_date'] + ' ' + entry['tournament_name'] + ' [' + entry['tournament_id'] + ']'

parser = argparse.ArgumentParser(description='Script to fetch tournament', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-d', '--debug', action='store_true')
parser.add_argument('-c', '--config', default='config.ini')
parser.add_argument('-y', '--year', default=str(datetime.date.today().year))
args = parser.parse_args()
args = vars(args)

# Read the config
config = config.readConfig(filename=args['config'])
calendar = ifpa.getCalendar(config['ifpa']['apikey'], 'Australia')
calendar = filterCalendar(calendar, state='Vic', year=args['year'])

# Connect to database
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()

# Loop over entries checking if we have processed it already
newEvents = []
for entry in calendar:
    cursor.execute('SELECT count(id) FROM event WHERE ifpa_id = ' + entry['tournament_id']);
    result = cursor.fetchone()
    if result[0] == 0:
        newEvents.append(entry['tournament_id'])

# For each tournament to update
# Retreive new data
# Process the standings
# Update the database

# Close the database
cursor.close()
conn.close()
