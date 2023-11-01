#!/usr/bin/python3

from configparser import ConfigParser

def readConfig(filename='config.ini'):
    # create a parser
    parser = ConfigParser()
    # read config file
    parser.read(filename)

    config = {}
    for section in parser.sections():
        config[section] = {}
        params = parser.items(section)
        for param in params:
            config[section][param[0]] = param[1]

    return config
