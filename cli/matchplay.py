#!/usr/bin/python3

import requests

def getTournament(tournamentId):
    # Fetch the tournament details from the Matchplay site
    apiurl = "https://next.matchplay.events/api/tournaments/" + tournamentId
    response = requests.get(apiurl)
    return response.json()['data']

def getPlayers(tournamentId):
    apiurl = "https://next.matchplay.events/api/tournaments/" + tournamentId + "?includePlayers=True"
    response = requests.get(apiurl)
    players = {}
    for player in response.json()['data']['players']:
        players[player['playerId']] = player['name']
    return players

def getStandings(tournamentId):
    apiurl = "https://next.matchplay.events/api/tournaments/" + tournamentId + "/standings"
    response = requests.get(apiurl)
    return response.json()
