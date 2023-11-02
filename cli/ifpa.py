#!/usr/bin/python3

import requests

def getCalendar(apikey, country):
    # Get the calendar of past events
    params = { 'api_key': apikey, 'country': country }
    url = 'https://api.ifpapinball.com/v1/calendar/history'
    r = requests.get(url, params=params)
    if r.status_code != 200:
        r.raise_for_status()

    return r.json()['calendar']

def getTournamentResults(apikey, tournamentId):
    params = { 'api_key': apikey }
    url = 'https://api.ifpapinball.com/v1/tournament/' + tournamentId + '/results'

    r = requests.get(url, params=params)
    if r.status_code != 200:
        r.raise_for_status()

    return r.json()['tournament']
