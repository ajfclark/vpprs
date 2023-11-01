#!/usr/bin/python3

import requests

def getCalendar(apikey, country):
    # Get the calendar of past events
    params = { 'api_key': apikey, 'country': country }
    r = requests.get('https://api.ifpapinball.com/v1/calendar/history', params=params)
    if r.status_code != 200:
        r.raise_for_status()

    return r.json()['calendar']
