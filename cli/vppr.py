#!/usr/bin/python3

import psycopg2

def vppr(place: float, numPlayers: int) -> float:
    if(place == 1.0):
        return float(50)
    else:
        return float(((int(numPlayers) - float(place) + 1) / numPlayers)**2 * 45 + 1)

def getPlayerId(cursor, name: str) -> int:
    cursor.execute("SELECT id FROM player WHERE name='" + str(name) + "';")

    temp = cursor.fetchone()
    if temp != None:
        playerId = list(temp)[0]
    else:
        playerId = None

    return playerId

def addPlayer(cursor, name: str) -> int:
    cursor.execute("INSERT INTO player(name) VALUES ('%s') RETURNING id;" % (name))
    return int(cursor.fetchone()[0])

