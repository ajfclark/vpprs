#!/usr/bin/python3

import requests
import csv

def getTournament(tournamentId):
    # Fetch the tournament details from the Matchplay site
    apiurl = "https://next.matchplay.events/api/tournaments/" + tournamentId
    response = requests.get(apiurl)
    return response.json()['data']

def getPlayers(tournamentId):
    apiurl = "https://next.matchplay.events/api/tournaments/" + tournamentId + "/players/csv"
    response = requests.get(apiurl)
    lines = list(csv.reader(response.text.splitlines()))
    players = {}
    for line in lines:
        players[line[0]] = line[1]
    players['163181']='Maria Papoulias'
    players['244600']='David Leeds'
    players['94715']='Darren Lewis'
    players['47675']='Ryan Cee'
    players['155474']='Leigh Ashlin'
    players['523']='John Ebejer'
    players['45063']='John Ebejer'
    players['42848']='Stacey Borg'
    players['72344']='Simon Raik-Allen'
    players['42845']='Stuart Thornton'
    return players

def getStandings(tournamentId):
    players = getPlayers(tournamentId)
    apiurl = "https://next.matchplay.events/api/tournaments/" + tournamentId + "/standings"
    response = requests.get(apiurl)
    rows = response.json()
    data = []
    for row in rows:
        place = row['position']
        playerId = row['playerId']
        name = players[str(playerId)]
        data.append({ 'placing': place, 'name': name })
    return data
