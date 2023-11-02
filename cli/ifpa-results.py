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

def getPlayerData(results):
    data = []
    for result in tournament['results']:
        place = float(result['position'])
        name = result['first_name'].strip() + ' ' + result['last_name'].strip()
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

if(args['tournamentid']):
    calendar = [ {'tournament_id': args['tournamentid'] } ]
else:
    # Look at the calendar for new events
    calendar = ifpa.getCalendar(config['ifpa']['apikey'], 'Australia')
    calendar = filterCalendar(calendar, state='Vic', year=args['year'])

# Connect to database
conn = psycopg2.connect(**config['postgresql'])
cursor = conn.cursor()
cursor.execute('SELECT ifpa_id FROM event WHERE ifpa_id is not null')
dbTournamentIds = [tournamentId for row in cursor for tournamentId in row]

# Loop over entries checking if we have processed it already
tournamentIds = []
for entry in calendar:
    if int(entry['tournament_id']) not in dbTournamentIds:
        tournamentIds.append(entry['tournament_id'])

# For each tournament to update
for tournamentId in tournamentIds:
    # Retreive new data
    tournament = ifpa.getTournamentResults(config['ifpa']['apikey'], tournamentId)

    # Process the standings
    data = getPlayerData(tournament['results'])

    # Debug output
    print(tournament['event_date'] + ":" + tournament['tournament_name'])
    for player in data:
        print(player)

    # Update the database
    cursor.execute("INSERT INTO event(date, name, ifpa_id) VALUES (%s, %s, %s) RETURNING id;", (tournament['event_date'], tournament['tournament_name'], tournamentId))
    eventId = str(cursor.fetchone()[0])

    # Add results to result table
    sqlData = []
    for player in data:
        sqlData.append([eventId,str(player['placing']),player['name']])
    cursor.executemany("INSERT INTO result(event_id, place, player) VALUES (%s, %s, %s);", sqlData)

    if(not debug):
        conn.commit()

# Close the database
cursor.close()
conn.close()
