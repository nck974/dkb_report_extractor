# https://tabula-py.readthedocs.io/en/latest/tabula.html
from tabula import convert_into_by_batch
from tabula import convert_into
import os
import re
import sys 

directory=sys.argv[1]
output=sys.argv[2]
print(directory)
print(output)
files = [f for f in os.listdir(directory) if re.match(r'.+\.pdf', f)]
for file in files:
    print(os.path.join(directory, file))
    convert_into(os.path.join(directory, file), output_path=os.path.join(output, file.replace(".pdf",".csv" )), pages='all', area=[[409,39,750,590]])
