#!/usr/bin/python3

import httplib2
from bs4 import BeautifulSoup
import argparse

parser = argparse.ArgumentParser(description="Script to fetch tournament results and dump a CSV",
	formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-t", "--tournament", required=True)
args = parser.parse_args()
config = vars(args)

http = httplib2.Http()
status, response = http.request('http://www.ifpapinball.com/tournaments/view.php?t=' + config['tournament'])

soup = BeautifulSoup(response, 'html.parser') 

table = soup.find("table", id="tourresults").tbody
rows = table.find_all("tr")

data = []
for row in rows:
	td = row.find_all("td")
	place = td[0].contents[0]
	name = td[1].a.contents[0]
	data.append({ "place": place, "name": name })

for i in range(len(data)):
	print(str(i) + ":" + str(data[i]))
