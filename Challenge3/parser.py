import json
import argparse
import re

p = argparse.ArgumentParser()
p.add_argument('--file',nargs=1,
help="Json object file to pass",
type=argparse.FileType('r')) # take the arg 1 and open as file in read mode

p.add_argument('--key', nargs=1,
help="key to pass in",
type=str)

arguments = p.parse_args()

decod = re.sub(r"[^a-zA-Z0-9]+", ' ', arguments.key[0]) #remove the / from key and subtitute with lank space
ki = decod.split() #split the remaining key in an array

d = json.load(arguments.file[0]) #load json file into a dict
ans = d[ki[0]][ki[1]][ki[2]] # pass the key objects values in json dict to get the value
print(ans)
