import requests
import json

from time import sleep
from pprint import pprint


if __name__ == "__main__":

    OUTFILE = 'mem_use.csv'

    while True:
        response = requests.get('http://localhost:9200/_nodes/stats/breaker')
        data = json.loads(response.text)
        use = data['nodes']['4GijL0phSQK1LhM94i2pKg']['breakers']['request']['estimated_size_in_bytes']
        lim = data['nodes']['4GijL0phSQK1LhM94i2pKg']['breakers']['request']['limit_size_in_bytes']
        perc = round(use / lim * 100, 2)
        print(perc)

        with open(OUTFILE, 'a+') as outfile:
            outfile.write(str(perc) + '\n')
        sleep(10)

