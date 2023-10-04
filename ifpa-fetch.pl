#!/usr/bin/python3

import httplib2
from bs4 import BeautifulSoup

http = httplib2.Http()
status, response = http.request('http://www.ifpapinball.com/tournaments/view.php?t=64751')

soup = BeautifulSoup(response, 'html.parser') 

table = soup.find("table", id="tourresults").tbody
rows = table.find_all("tr")

for row in rows:
	td = row.find_all("td")
	rank = td[0].contents[0]
	name = td[1].a.contents[0]

	print(rank + "," + name)
