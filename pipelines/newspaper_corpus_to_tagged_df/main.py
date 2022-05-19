####
#### Remember to create virtual python enviroment first:
#### python3 -m venv .venv
#### source .venv/bin/activate

#### Remember to install requirments:
#### pip install -r requirements

#### Remember to install python -m spacy download en_core_web_lg
# required imports

# project functions imports
from cleaning_functions import *
from pos_tagging_functions import *

sentences_column = "sentences"
path_to_newspapers = "../../../GitHub/ciphersofthetimes/data/corpora/newspapers_test/"
# path_to_newspapers = "../../data/corpora/newspapers_test/"
path_to_spreadsheets = "../../../GitHub/ciphersofthetimes/data/spreadsheets/"
#path_to_spreadsheets = "../../data/spreadsheets/"

def main():
    print("[+] Starting newspaper corpus processor...")
    print(f"[+] Using default values:")
    print(f"[+] Path to newspapers is: {path_to_newspapers}")
    print(f"[+] Path to spreadsheets is: {path_to_spreadsheets}")
    print(f"[+] Sentences column name is: {sentences_column}")

    # path_to_newspapers = input("[+] Please input path to newspaper corpus: /Users/leehusigler/Documents/GitHub/ciphersofthetimes/data/corpora/newspapers_test")
    print(f"[+] Importing corpus of dirty texts from {path_to_newspapers}")
    dirty_texts = input_corpus_of_txts(path=path_to_newspapers)
    print("[+] Processing dirty texts")
    df = process_dirty_texts_to_df(dirty_texts)
    print("[+] Dataframe created.")
    print("[+] Beginning POS tagging ...")
    df = pos_tag_texts_from_df(df, 'sentences')
    print("[+] Completed POS tagging.")
    print("[+] Dataframe head looks like this: ")
    print(df.head())
    print("[+] Saving dataframe...")
    output_full(df=df, path_to_spreadsheets=path_to_spreadsheets)
    print("[+] Program completed. Exiting...")
    exit()

if __name__=="__main__":
    main()