#!/usr/bin/python3

import sys
import argparse
import psycopg2
import requests
import datetime
from configparser import ConfigParser

import config

parser = argparse.ArgumentParser(description='Script to fetch tournament', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-d', '--debug', action='store_true')
parser.add_argument('-c', '--config', default='config.ini')
parser.add_argument('-y', '--year', default=str(datetime.date.today().year))
args = parser.parse_args()
args = vars(args)

# Read the config
config = config.readConfig(filename=args['config'])

params = { 'api_key': config['ifpa']['apikey'], 'country': 'Australia' }
r = requests.get('https://api.ifpapinball.com/v1/calendar/history', params=params)
if r.status_code != 200:
    r.raise_for_status()
    sys.exit()

events = []
calendar = r.json()['calendar']
for event in calendar:
    if event['state'] == 'Vic' and event['start_date'][:4] == args['year']:
        tournament = event['start_date'] + ' ' + event['tournament_name'] + ' [' + event['tournament_id'] + ']'
        if event['results_status'] == 'Submitted':
            events.append(event)
        else:
            print('No results yet for ' + tournament)

# Connect to database
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()

for event in events:
    cursor.execute('SELECT count(id) FROM event WHERE ifpa_id = ' + event['tournament_id']);
    result = cursor.fetchone()
    if result[0] == 0:
        tournament = event['start_date'] + ' ' + event['tournament_name'] + ' [' + event['tournament_id'] + ']'
        print('Nothing in the db for ' + tournament)

# Add results to result table
cursor.close()
conn.close()
    
