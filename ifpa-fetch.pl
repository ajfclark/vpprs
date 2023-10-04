#!/usr/bin/python3

import httplib2
from bs4 import BeautifulSoup
import argparse

parser = argparse.ArgumentParser(description='Script to fetch tournament results and dump a CSV',
	formatter_class=argparse.ArgumentDefaultsHelpFormatter)
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('-t', '--tournament')
group.add_argument('-f', '--file')
args = parser.parse_args()
config = vars(args)

if(config['tournament']):
	http = httplib2.Http()
	status, htmlPage = http.request('http://www.ifpapinball.com/tournaments/view.php?t=' + config['tournament'])
if(config['file']):
	f = open(config['file'])
	htmlPage = f.read()

soup = BeautifulSoup(htmlPage, 'html.parser') 

table = soup.find('table', id='tourresults').tbody
rows = table.find_all('tr')

data = []
for row in rows:
	cells = row.find_all('td')
	place = cells[0].contents[0].strip()
	name = cells[1].a.contents[0].strip()
	data.append({ 'placing': place, 'name': name })

for i in range(len(data)):
	matches = [ i ]
	for k in range(i + 1, len(data)):
		if(data[i]['placing'] == data[k]['placing']):
			matches.append(k)
	if(len(matches) > 1):
		total = 0
		for k in range(len(matches)):
			total = total + int(matches[k]) + 1
		average = total / len(matches)
		for k in range(len(matches)):
			data[matches[k]]['placing'] = average

for player in data:
	print(str(player['placing']) + '	' + player['name'])
