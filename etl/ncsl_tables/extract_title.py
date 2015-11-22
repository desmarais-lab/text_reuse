from __future__ import unicode_literals
import io


with io.open('ncsl_table_urls.txt', 'r') as infile, io.open('tables.csv', 'w+') as outfile:
    outfile.write('title, url\n')
    for line in infile:
        line = line.replace('\n', '')
        els = line.split('/')

        title = els[-1].replace('.aspx', '')
        title = title.replace('-', ' ')
        newline = '{},{}\n'.format(title, line)
        outfile.write(newline)
