#!/usr/bin/python3

import requests
import logging

def searchTournaments(apikey, country, state, year):
    params = { 'country': country, 'stateprov': state, 'start_date': str(year) + '-01-01', 'end_date': str(year) + '-12-31'}
    headers = { 'X-API-Key': apikey, 'accept': 'application/json' }
    url = 'https://api.ifpapinball.com/tournament/search'
    r = requests.get(url, params=params, headers=headers)
    if r.status_code != 200:
        r.raise_for_status()

    try:
        json = r.json()
        tournaments = json['tournaments']
    except Exception as err:
        print(f"Unexpected {err=}, {type(err)=}")
        print(f"{r=}")
        raise

    return tournaments

def getTournamentResults(apikey, tournamentId):
    logger=logging.getLogger('ifpa')

    params = { 'api_key': apikey }
    url = 'https://api.ifpapinball.com/v1/tournament/' + str(tournamentId) + '/results'

    r = requests.get(url, params=params)
    if r.status_code != 200:
        r.raise_for_status()

    data = r.json()['tournament']
    logger.debug(type(tournamentId));
    logger.debug(type(data['tournament_id']));
    logger.debug('"' + str(tournamentId) + '"');
    logger.debug('"' + str(data) + '"');

    if data['tournament_id'] == str(tournamentId):
        return data

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
