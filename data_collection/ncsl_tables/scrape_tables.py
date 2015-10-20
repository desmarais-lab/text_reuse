from __future__ import print_function, unicode_literals
from xgoogle.search import GoogleSearch
import io
from time import sleep
from random import randint

outfile = io.open('ncsl_table_urls.txt', 'w+', encoding='utf-8')
gs = GoogleSearch('site:ncsl.org "laws.aspx"')
gs.results_per_page = 25 
results = []

tmp = 1
while tmp is not None:
    sleep(randint(0,100))
    tmp = gs.get_results()
    results.extend(tmp)

outfile.write('title,description,url')
for res in results:
    row = '{},{},{}\n'.format(res.title, res.desc, res.url)
    outfile.write(row)

outfile.close()
