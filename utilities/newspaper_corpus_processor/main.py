### This file is the main file of the newspaper processor script.
### A user is required to supply a path and an output file name.
### It begins by grabbing the texts from the supplied path,
### and preprocesses and cleans the texts by using regex,
### standardizing foreign characters, and cleaning line notations.
### It then inputs this information into a pandas dataframe,
### where POS tagging is applied to each sentence, and the resulting
### information is added to the dataframe. Finally, it saves the processed
### dataframe as a CSV file in a user supplied path. 

### TO USE:
### Remember to create virtual python enviroment first:
### python3 -m venv .venv
### source .venv/bin/activate

### Remember to install requirments:
### pip install -r requirements.txt

### Remember to install python -m spacy download en_core_web_lg

### Remember to install nltk via python
###   >>> import nltk
###   >>> nltk.download('punkt')

# project imports
from cleaning_functions import *
from pos_tagging_functions import *
from command_line import *

### Main program function, which outputs information as the program is running.
def main():
    # get command line configuration from command_line.py
    try:
        paths_to_corpora, path_to_spreadsheets, output_name = parser_setup()
        list_of_sample_newspapers = None
    except Exception as e:
        
        paths_to_corpora, path_to_spreadsheets, output_name, sample_number = parser_setup()
        print("Creating sample files with {sample_number} issues per month")
        list_of_sample_newspapers = get_sample_newspapers(paths_to_corpora[0], int(sample_number))

    dirty_texts = import_corpora(paths_to_corpora, list_of_sample_newspapers)
    # for corpus in paths_to_corpora:
    #     print(f"[+] Importing corpus of dirty texts from {corpus}")
    #     dirty_texts.append(import_corpus_from_path(path=corpus))
    print("[+] Processing dirty texts...")
    df = process_dirty_texts_to_df(dirty_texts)
    print(f"[-] Dataframe created. Shape is {df.shape}")
    print("[+] Running POS tagging and integrating titles and names into single PROPNs...")
    df = pos_tag_texts_from_df_new(df, 'sentences')
    print("\n[-] Completed POS tagging.")
    print("\n[!] Dataframe head looks like this: ")
    print(f"First elements of sentences column: {df.head().sentences.values}")
    print(f"First elements of tagged_sentences column: {df.head().text_.values[0]}")
    print(f"First elements of pos_counts column: {df.head().tags_.values[0]}\n")

    # print("Now creating df with words as documents...")
    # df_words = documents_as_sentences_to_documents_as_words(df)

    print("[+] Saving dataframe...")
    try:
        output_full(df=df, path_to_spreadsheets=path_to_spreadsheets, output_file_name=output_name)
        # output_full(df=df_words, path_to_spreadsheets=path_to_spreadsheets, output_file_name=output_name + "_words")
        output_meta(df=df, path_to_spreadsheets=path_to_spreadsheets, output_file_name=output_name)
    except Exception as e:
        print("Unable to save dataframe as CSV. (Make sure that the folder exists.")
    
    print("[+] Program successfully completed. Exiting...")
    exit(0)

if __name__=="__main__":
    main()