#!/usr/bin/python3

def vppr(place: float, numPlayers: int) -> float:
    if(place == 1.0):
        return str(50)
    else:
        return str(((int(numPlayers) - float(place) + 1) / numPlayers)**2 * 45 + 1)
