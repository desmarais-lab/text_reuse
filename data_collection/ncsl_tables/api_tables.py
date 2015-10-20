from __future__ import print_function, unicode_literals
from pygoogle import pygoogle
from pprint import pprint
import re
import io
import logging  

# Display progress logs on stdout
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s %(levelname)s %(message)s')

# Config
URLFILE = 'ncsl_table_urls.txt'
FROM_WEB = True
PAGES = 10


if FROM_WEB:
    g = pygoogle('site:ncsl.org "laws.aspx"')
    g.pages = 10
     
    urls = g.get_urls()
    with io.open(URLFILE, 'w+', encoding='utf-8') as urlfile:
        for url in urls:
            urlfile.write(url + '\n')
else: 
    pass

## Check domain
# u'http://www.ncsl.org/research/human-services/state-doma-laws.aspx'
keep_re = re.compile('.+/research/.+\.aspx$')
for url in urls:
    if keep_re.match(url) is None:
        print(url)

