from __future__ import unicode_literals
import urllib2
import json
from pprint import pprint
import io
import time
import re

def bing_request(offset, keyBing):
    credentialBing = 'Basic ' + (':%s' % keyBing).encode('base64')[:-1] # the "-1" is to remove the trailing "\n" which encode adds
    searchString = '%27site%3Ancsl.org%20%22laws.aspx%22%27'
    top = 50
    url = 'https://api.datamarket.azure.com/Bing/Search/Web?' + \
          'Query=%s&$top=%d&$skip=%d&$format=json' % (searchString, top, offset)
    request = urllib2.Request(url)
    request.add_header('Authorization', credentialBing)
    requestOpener = urllib2.build_opener()
    response = requestOpener.open(request) 
    response = json.load(response)
    return response

outfile = io.open('../../data/ncsl/scraped_table_urls_laws.csv', 'w+', encoding='utf-8')
outfile.write('id,title,url,description,uri\n')
offset = 0
punct = re.compile(r'[,;\t|]')
key = io.open('bing_key.txt').read().strip('\n')

while True:
    
    print 'Requesting results {} to {}'.format(offset, (offset + 50))
    response = bing_request(offset, key)
    
    for result in response['d']['results']:
        # Extract info
        id_ = result['ID']
        title = punct.sub('', result['Title'])
        url_ = result['Url']
        description = punct.sub('', result['Description'])
        
        # Write row to file
        row = '{},{},{},{}\n'.format(id_,title,url_,description)
        outfile.write(row)

    if '__next' not in response['d'].keys():
        break
    else:
        offset += 50
    
outfile.close()
