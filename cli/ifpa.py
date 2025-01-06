#!/usr/bin/python3

import requests
import logging

def getCalendar(apikey, country):
    # Get the calendar of past events
    params = { 'api_key': apikey, 'country': country }
    url = 'https://api.ifpapinball.com/v1/calendar/history'
    r = requests.get(url, params=params)
    if r.status_code != 200:
        r.raise_for_status()

    try:
        json = r.json()
        calendar = json['calendar']
    except Exception as err:
        print(f"Unexpected {err=}, {type(err)=}")
        print(f"{r=}")
        raise

    return calendar

def getTournamentResults(apikey, tournamentId):
    logger=logging.getLogger('ifpa')

    params = { 'api_key': apikey }
    url = 'https://api.ifpapinball.com/v1/tournament/' + str(tournamentId) + '/results'

    r = requests.get(url, params=params)
    if r.status_code != 200:
        r.raise_for_status()

    data = r.json()['tournament']
    if data['tournament_id'] == str(tournamentId):
        return data

    logger.debug(type(tournamentId));
    logger.debug(type(data['tournament_id']));
    logger.debug('"' + str(tournamentId) + '"');
    logger.debug('"' + str(data['tournament_id']) + '"');
    return None

def searchPlayer(apikey, name):
    params = { 'api_key': apikey, 'q': name }
    url = 'https://api.ifpapinball.com/v1/player/search'
    
    r = requests.get(url, params=params)
    if r.status_code != 200:
        r.raise_for_status()

    ret = r.json()['search']
    if ret == 'No players found':
        return None
    else:
        return ret
