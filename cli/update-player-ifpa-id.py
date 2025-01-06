#!/usr/bin/python3

import sys
import argparse
import psycopg2
import logging

import config
import ifpa
import vppr

parser = argparse.ArgumentParser(description='Script to fetch tournament', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-d', '--debug', action='store_true')
parser.add_argument('-c', '--config', default='../config.ini')
args = parser.parse_args()
args = vars(args)

debug = args['debug']

if debug:
    logging.basicConfig(level=logging.DEBUG)
else:
    logging.basicConfig(level=logging.INFO)
logging.getLogger("urllib3").setLevel(logging.INFO)

logger = logging.getLogger('update-player-ifpa-id')

# Read the config
config = config.readConfig(filename=args['config'])

# Connect to database
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()
cursor2 = conn.cursor()
cursor.execute('SELECT id, name FROM player WHERE ifpa_id IS NULL')

sqlData = []
for row in cursor:
    vpprid=row[0]
    vpprname=row[1]
    candidates = ifpa.searchPlayer(config['ifpa']['apikey'], vpprname)
    if candidates == None:
        logging.info(vpprname + ': No candidates')
        continue
    for candidate in candidates:
        ifpaname = candidate['first_name'].strip() + ' ' + candidate['last_name'].strip()
        if ifpaname.lower() != vpprname.lower():
            logging.info(vpprname + ': not ' + ifpaname + ':' + str(candidate))
            continue
        if candidate['country_code'] != 'AU':
            logging.info(vpprname + ': Not AU:' + str(candidate))
            continue
        logging.info(vpprname + ': Found:' + str(candidate))
        query = "UPDATE player SET ifpa_id=" + candidate['player_id'] + " WHERE id=" + str(vpprid) +";"
        cursor2.execute(query)

if(not debug):
    conn.commit()
else:
    conn.rollback()

# Close the database
cursor.close()
conn.close()

