#!/usr/bin/python3

from bs4 import BeautifulSoup

f = open('66410.tidy.html')
contents = f.read()

soup = BeautifulSoup(contents, 'html.parser') 

table = soup.find("table", id="tourresults").tbody
rows = table.find_all("tr")

for row in rows:
	td = row.find_all("td")
	rank = td[0].contents[0]
	name = td[1].a.contents[0]

	print(rank + "," + name)
