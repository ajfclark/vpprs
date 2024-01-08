#!/usr/bin/python3

import sys
import argparse
import psycopg2

import config
import ifpa
import vppr

parser = argparse.ArgumentParser(description='Script to fetch tournament', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-d', '--debug', action='store_true')
parser.add_argument('-c', '--config', default='config.ini')
args = parser.parse_args()
args = vars(args)

debug = args['debug']

# Read the config
config = config.readConfig(filename=args['config'])

# Connect to database
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()
cursor2 = conn.cursor()
cursor.execute('SELECT id, name FROM player WHERE ifpa_id IS NULL')

sqlData = []
for row in cursor:
    print(str(row[0]) + ": " + row[1]) 
    candidates = ifpa.searchPlayer(config['ifpa']['apikey'], row[1])
    if candidates == None:
        continue
    for candidate in candidates:
        name = candidate['first_name'].strip() + ' ' + candidate['last_name'].strip()
        if name.lower() != row[1].lower():
            continue
        if candidate['country_code'] != 'AU':
            continue
        print("Found")
        query = "UPDATE player SET ifpa_id=" + candidate['player_id'] + " WHERE id=" + str(row[0]) +";"
        cursor2.execute(query)

if(not debug):
    conn.commit()
else:
    conn.rollback()

# Close the database
cursor.close()
conn.close()

