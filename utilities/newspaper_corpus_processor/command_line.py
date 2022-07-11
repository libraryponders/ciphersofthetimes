# imports
import sys
import os
import argparse

def parser_setup():
    ### Program usage description:
    usage_description = "python3 ./main.py -i <PATH_TO_CORPUS> -o <PATH_TO_OUTPUT_FOLDER> -n <OUTPUT_FILE_NAME>"
    ### Default values are hardcoded at the moment. Commented out variables
    ### are the variables that should be used while running from within the github
    ### folder. 
    output_name = "test"
    # path_to_newspapers = "../../../GitHub/ciphersofthetimes/data/corpora/newspapers_test/"
    # path_to_newspapers = "tests/newspapers_test/"
    path_to_newspapers = "/home/lyre/git_projects/work/ciphersofthetimes/data/corpora/newspapers_test/"
    # path_to_novels = "../../../GitHub/ciphersofthetimes/data/corpora/corpus_newspaper_novels_dated/"
    # path_to_novels = "tests/novels_test/"
    path_to_novels = "/home/lyre/git_projects/work/ciphersofthetimes/data/corpora/corpus_newspaper_novels_dated/"
    # path_to_spreadsheets = "../../../GitHub/ciphersofthetimes/data/spreadsheets/tests/"
    path_to_spreadsheets = "tests/spreadsheets_test/"

   
    
    if len(sys.argv) == 1:
        print(f"No arguments were provided. \nUsage: {usage_description}")
        print("\nTo run with default values use: 'python3 ./main.py -d'")
        print("Run 'python3 ./main.py -h' for more information.")
        exit(0)

    # create argument parser for command line input
    parser = argparse.ArgumentParser(description = usage_description, add_help=True)
    # setting up the program options and usage
    parser.add_argument("-inews", "--input_news", help = "the path to the folder from which to grab newspaper .txt files")
    parser.add_argument("-inovs", "--input_novs", help = "the path to the folder from which to grab novel .txt files")
    parser.add_argument("-o", "--output", help = "the path to the folder in which to save the outputted .csv files")
    parser.add_argument("-n", "--name", help = "the name to give the outputted csv files")
    parser.add_argument("-d", "--default", nargs='?', help = "use all default values for input and output files")
    parser.add_argument("-s", "--sample", nargs=1, help = "takes a number and returns a sample of texts from the corpus")
    args = parser.parse_args()
    os.system("clear")
    print("[+] Starting the CoTT (ciphers of _The Times_) corpus processor...")
    # getting user input
    if args.default:
        print(f"[+] Using default input path (newspapers): {path_to_newspapers}")
        print(f"[+] Using default input path (novels): {path_to_novels}")
        print(f"[+] Using default output path: {path_to_spreadsheets}")
        print(f"[+] Using default name: {output_name}")
    else:
        if args.input_news:
            path_to_newspapers = args.input_news
            print(f"[+] Supplied path to newspapers corpus is: {path_to_newspapers}")
        else:
            print(f"[+] Using default input path: {path_to_newspapers}")
        # getting 
        if args.input_novs:
            path_to_novels = args.input_novs
            print(f"[+] Supplied path to novels corpus is: {path_to_novels}")
        else:
            print(f"[+] Using default input path: {path_to_novels}")

        if args.output:
            path_to_spreadsheets = args.output
            print(f"[+] Supplied output folder for csv files is: {path_to_spreadsheets}")
        else: 
            print(f"[+] Using default output path: {path_to_spreadsheets}")
        if args.name:
            output_name = args.name
            print(f"[+] Supplied name for csv files is: {output_name}")
        else:
            print(f"[+] Using default name: {output_name}")
    if args.sample:
        sample_number = int(args.sample[0])
        return([path_to_newspapers, path_to_novels], path_to_spreadsheets, output_name, sample_number)

    return([path_to_newspapers, path_to_novels], path_to_spreadsheets, output_name)
