#!/usr/bin/python3

import httplib2
from bs4 import BeautifulSoup
import argparse

parser = argparse.ArgumentParser(description="Script to fetch tournament results and dump a CSV",
	formatter_class=argparse.ArgumentDefaultsHelpFormatter)
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument("-t", "--tournament")
group.add_argument("-f", "--file")
args = parser.parse_args()
config = vars(args)

if(config['tournament']):
	http = httplib2.Http()
	status, htmlPage = http.request('http://www.ifpapinball.com/tournaments/view.php?t=' + config['tournament'])
if(config['file']):
	f = open(config['file'])
	htmlPage = f.read()

soup = BeautifulSoup(htmlPage, 'html.parser') 

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
