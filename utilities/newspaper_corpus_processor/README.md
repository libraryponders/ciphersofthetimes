
# Newspaper Corpus Processor

This script was created to supplement the efforts 
of the Ciphers of _the Times_ research project. 
Its purpose is to transform a directory of .txt files 
(a folder of OCRed newspaper text in our case) into 
cleaned and preprocessed .csv files to be used with an R-based
classification model.

## Usage/Examples

```python3 ./main.py -i <PATH_TO_CORPUS> -o <PATH_TO_OUTPUT_FOLDER> -n <OUTPUT_FILE_NAME>```

This is best used within a python3 virtual enviroment.
To set up, run the following commands inside the main folder:


`python3 -m venv .venv`



`source .venv/bin/activate`

`pip install -r requirements`

If you haven't used spacy before, you will probably need to download the English language package:

`python -m spacy download en_core_web_lg`

## Repo Authors

- Leehu Ben Sigler


## Acknowledgements

 - Principal Investiagor: Professor Nathalie Cooke
 - Research Assistants:
    - Ronny Litvak-Katzman
    - Lillian Simons
   
*** This project is funded by the Social Sciences and Humanities Research Council of Canada.

