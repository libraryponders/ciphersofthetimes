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
### pip install -r requirements

### Remember to install python -m spacy download en_core_web_lg

# imports
import argparse
# project imports
from cleaning_functions import *
from pos_tagging_functions import *

### Program usage description:
usage_description = "python3 ./main.py -i <PATH_TO_CORPUS> -o <PATH_TO_OUTPUT_FOLDER> -n <OUTPUT_FILE_NAME>"

### Main program function, which outputs information as the program is running.
def main():
    ### Default values are hardcoded at the moment. Commented out variables
    ### are the variables that should be used while running from within the github
    ### folder. 
    output_name = "test"
    path_to_newspapers = "../../../GitHub/ciphersofthetimes/data/corpora/newspapers_test/"
    # path_to_newspapers = "../../data/corpora/newspapers_test/"
    path_to_spreadsheets = "../../../GitHub/ciphersofthetimes/data/spreadsheets/tests/"
    #path_to_spreadsheets = "../../data/spreadsheets/"
    
    if len(sys.argv) == 1:
        print("No arguments were provided. \nUsage: ")
        print(usage_description)
        print("\nTo run with default values use: 'python3 ./main.py -d'")
        print("Run 'python3 ./main.py -h' for more information.")
        exit(0)
    
    # create argument parser for command line input
    parser = argparse.ArgumentParser(description = usage_description, add_help=True)
    # setting up the program options and usage
    parser.add_argument("-i", "--input", help = "the path to the folder from which to grab .txt files")
    parser.add_argument("-o", "--output", help = "the path to the folder in which to save the outputted .csv files")
    parser.add_argument("-n", "--name", help = "the name to give the outputted csv files")
    parser.add_argument("-d", "--default", nargs='?', help = "use all default values for input and output files")
    args = parser.parse_args()

    print("[+] Starting the newspaper corpus processor...")
    # getting user input
    if args.default:
        print(f"[+] Using default input path: {path_to_newspapers}")
        print(f"[+] Using default output path: {path_to_newspapers}")
        print(f"[+] Using default name: {output_name}")
    else:
        if args.input:
            path_to_newspapers = args.input
            print(f"[+] Supplied path to corpus is: {path_to_newspapers}")
        else:
            print(f"[+] Using default input path: {path_to_newspapers}")

        if args.output:
            path_to_spreadsheets = args.output
            print(f"[+] Supplied output folder for csv files is: {path_to_spreadsheets}")
        else: 
            print(f"[+] Using default output path: {path_to_newspapers}")
        if args.name:
            output_name = args.name
            print(f"[+] Supplied name for csv files is: {output_name}")
        else:
            print(f"[+] Using default name: {output_name}")

    print(f"[+] Importing corpus of dirty texts from {path_to_newspapers}")
    dirty_texts = input_corpus_of_txts(path=path_to_newspapers)
    print("[+] Processing dirty texts...")
    df = process_dirty_texts_to_df(dirty_texts)
    print("[-] Dataframe created.")
    print("[+] Running POS tagging and integrating titles and names into single PROPNs...")
    df = pos_tag_texts_from_df(df, 'sentences')
    print("\n[-] Completed POS tagging.")
    print("\n[!] Dataframe head looks like this: ")
    print(f"First elements of sentences column: {df.head().sentences.values}")
    print(f"First elements of tagged_sentences column: {df.head().tagged_sentences.values[0]}")
    print(f"First elements of pos_counts column: {df.head().pos_counts.values[0]}\n")

    print("Now creating df with words as documents...")
    df_words = documents_as_sentences_to_documents_as_words(df)

    print("[+] Saving dataframe...")
    try:
        output_full(df=df, path_to_spreadsheets=path_to_spreadsheets, output_file_name=output_name)
        output_full(df=df_words, path_to_spreadsheets=path_to_spreadsheets, output_file_name=output_name + "_words")
        output_meta(df=df, path_to_spreadsheets=path_to_spreadsheets, output_file_name=output_name)
    except Exception as e:
        print("Unable to save dataframe as CSV. (Make sure that the folder exists.")
    
    print("[+] Program successfully completed. Exiting...")
    exit(0)

if __name__=="__main__":
    main()