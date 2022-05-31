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
path_to_spreadsheets = "../../../GitHub/ciphersofthetimes/data/spreadsheets/tests/"
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
    print("[+] Processing dirty texts...", end=" -> ")
    df = process_dirty_texts_to_df(dirty_texts)
    print("[-] Dataframe created.")
    print("[+] Running POS tagging and integrating titles and names into single PROPNs...")
    df = pos_tag_texts_from_df(df, 'sentences')
    print("[-] Completed POS tagging.\n")
    print("[!] Dataframe head looks like this: ")
    print(f"First elements of sentences column: {df.head().sentences.values}")
    print(f"First elements of tagged_sentences column: {df.head().tagged_sentences.values[0]}")
    print(f"First elements of pos_counts column: {df.head().pos_counts.values[0]}\n")

    print("\nNow creating df with words as documents...")
    df_words = documents_as_sentences_to_documents_as_words(df)

    print("[+] Saving dataframe...")
    try:
        if len(sys.argv) > 1:
            output_full(df=df, path_to_spreadsheets=path_to_spreadsheets, output_file_name=sys.argv[1])
            output_full(df=df_words, path_to_spreadsheets=path_to_spreadsheets, output_file_name=sys.argv[1] + "_words")
            output_meta(df=df, path_to_spreadsheets=path_to_spreadsheets, output_file_name=sys.argv[1])
        else:
            output_full(df=df, path_to_spreadsheets=path_to_spreadsheets)
            print("Saving version of database with words as documents, please enter appropriate name:")
            output_full(df=df_words, path_to_spreadsheets=path_to_spreadsheets)
            output_meta(df=df, path_to_spreadsheets=path_to_spreadsheets)
    except Exception as e:
        print("Unable to save dataframe as CSV. (Make sure that the folder exists.")
    
    
    print("[+] Program successfully completed. Exiting...")
    exit()

if __name__=="__main__":
    main()