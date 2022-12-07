### This file contains cleaning and preprocessing functions run on the newspaper corpus before
### running POS tags. The pipeline has been broken down into several smaller functions for
### readability. 

# imports:
import codecs
from nltk.tokenize import sent_tokenize
import os
import pandas as pd
import re
import unicodedata

# project imports:
from utility_code import *

### regex:
### This is a simple dictionary of the regex expressions to find during the 
### preprocessing stage of the text. Some of these are placeholders for expressions to be added.
regex_expressions = {"initials": r"\b([A-Z][.](\s)?)+", "prefixes": r"(Mr|St|Mrs|Ms|Dr|Esq|Sec|Secretar)[.]",\
                     "addresses": "", "dates": "", "line_break": r"¬\n", "space": r"/s",\
                     "dashes": r"[-]+", "quote_marks": r"(“|”)", \
                     "months_abrv": r"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[.](\s*(\d{1,2})(,|\.)?)?(\s*\d+)?",\
                     "pennies": r"(\d+[.]?\s*)[d][.]", "months_and_years": r"\d{1,2}[.]\s*(\d{4})",
                     "project_gutenberg_beginning": r"((\s?\*\s?)+(.)*(start)(.)*(gutenberg)(.)*)",
                     "project_gutenberg_end": r"((\s?\*\s?)+(.)*(end)(.)*(gutenberg)(.)*)"}

### For standardizing filenames/dates
dates_change = {"JAN": "01", "FEB": "02", "MAR": "03", "APR": "04", "MAY": "05",
    "JUN": "06", "JUL": "07", "AUG": "08", "SEP": "09", "OCT": "10", "NOV": "11", "DEC": "12"}

### Strips all the meta information and liscencing that project gutenberg adds
# def strip_gutenberg_related_text(text):
#    ## check for start gutenberg text
#    try:
#        split_text = re.split(regex_expressions["project_gutenberg_beginning"], text, maxsplit=2, flags=re.IGNORECASE)
#        new_text = split_text[1]    
#    except Exception:
#        new_text = text
#    ## check for end gutenberg text
#    try:
#        split_text = re.split(regex_expressions["project_gutenberg_end"], new_text, maxsplit=1, flags=re.IGNORECASE)
#        new_text = split_text[0]
#    except Exception:
#        pass
#    return new_text

### Strips all accented characters in the text
def strip_accents(text):
    text = unicodedata.normalize('NFD', text).encode('ascii', 'ignore').decode("utf-8")
    return str(text)

### Substitutes periods for "<prd>" for all the regex functions that need it
def process_periods(text):
    # no matchobj needed since this is only called in other processing functions
    text = re.sub(r"[.]","<prd>", text)
    return text

### Substitutes commas for periods for regex functions
def process_periods_to_commas(matchobj):
    text = matchobj.group(0)
    text = re.sub(r"[.]", ",", text)
    return text

### Processes initials into a standardized format, replacing periods with <prd>
### and stripping spaces between initials. Ex: "E. N. H." -> "E<prd>N<prd>H<prd>"
def process_initials(matchobj):
    text = matchobj.group(0)
    text = process_periods(text)
    text = re.sub(r"\s*", "", text)
    text = text + " "
    return text

### Processes abbreviated months. Ex: "Dec." -> "Dec<prd>"
def process_months_abrv(matchobj):
    text = matchobj.group(0)
    text = process_periods(text)
    return text

### Processes abbreviated pennies. Ex: "d." -> "d<prd>"
def process_pennies(matchobj):
    text = matchobj.group(0)
    text = re.sub(r"d[.]?","pennies", text)
    text = process_periods(text)
    return text

### Processes formatted quotation marks. Ex: (“|”)
def process_quotes(matchobj):
    text = matchobj.group(0)
    text = re.sub(r"“","<open_quote>", text)
    text = re.sub(r"”","<close_quote>", text)
    return text

### Separates metadata from text file
def remove_metadata(text):
    text_head = text[:999]
    
    author_re = re.search('(?<=<Author: )(.*)(?=>)', text_head)
    if author_re: author = author_re.group()
    else: author = '?'
    
    gender_re = re.search('(?<=<Gender: )(.*)(?=>)', text_head)
    if gender_re: gender = gender_re.group()
    else: gender = '?'
    
    year_re = re.search('(?<=<Year: )(.*)(?=>)', text_head)
    if year_re: year = year_re.group()
    else: year = '?'
    
    source_re = re.search('(?<=<Source: )(.*)(?=>)', text_head)
    if source_re: source = source_re.group()
    else: source = '?'
    
    newsnovel_re = re.search('(?<=<News Novel: )(.*)(?=>)', text_head)
    if newsnovel_re: is_newsnovel = newsnovel_re.group()
    else: is_newsnovel = '?'
 
    stripped_head = [line for line in text_head.split('\n') if not line or not (line[0] == '<' and line[-1] == '>')]
    stripped_text = '\n'.join(stripped_head) + text[999:]
    return(stripped_text, author, gender, year, source, is_newsnovel)

### This function calls all the preprocessing functions from above
def preprocess_text(text, category=0):
    # newspapers
    if category == 0:
        # remove all the line breaks created by newspaper processor
        text = re.sub(regex_expressions["line_break"],"", text)
        # marking initials:
        text = re.sub(regex_expressions["initials"], process_initials, text)
        # process titles:
        text = re.sub(regex_expressions["prefixes"],"\\1<prd>", text, flags=re.IGNORECASE)
        # process month abbreviations:
        text = re.sub(regex_expressions["months_abrv"], process_months_abrv, text, flags=re.IGNORECASE)
        # process instances of months [period] year:
        text = re.sub(regex_expressions["months_and_years"], process_periods_to_commas, text)
        # process instances of "No."
        text = re.sub(r"(No|Nos)[.]","number", text, flags=re.IGNORECASE)
        # strip all dashes:
        text = re.sub(regex_expressions["dashes"], " ", text)
        # transform all quotes to ' " ':
        # Not sure if quote marks should be excised
        # text = re.sub(regex_expressions["quote_marks"], '"', text)
        # strip all pennies "XX d." in the text:
        text = re.sub(regex_expressions["pennies"], process_pennies, text)
        # strip all accents from the text:
    # category == 1 is novels
    else:
        # strip gutenberg info
        # text = strip_gutenberg_related_text(text)
        # process only titles and quotations for novels
        text = re.sub(regex_expressions["prefixes"],"\\1<prd>", text, flags=re.IGNORECASE)
        # process quotes - TODO!
        # text = re.sub(regex_expressions["quote_marks"], process_quotes, text)

    # remove all underscores
    text = text.replace("_", "")
    # strip accents for all texts
    text = strip_accents(text)
    return text

### This function is called after the preprocessing stage and after tokenizing
### all the sentences. It removes all newline notations and transforms multiple spaces
### into single spaces. Then it transforms all the entirely uppercase words 
### into lowercase, and places back the periods that were previously replaced
### by <prd>
def clean_tokenized_sent(sent):
    # removing newline notations
    clean_sent = re.sub('\n', ' ', sent)
    clean_sent = re.sub('\r', ' ', clean_sent)
    # transforming multiple spaces to one space
    clean_sent = re.sub('\s+',' ', clean_sent)
    split_sentence = clean_sent.split()
    
    # transform all the words that are completely uppercase to lowercase
    for index, word in enumerate(split_sentence):
        if (word.isupper()) and (len(word) > 1):
            new_word = word.lower()
            split_sentence[index] = new_word
    clean_sent = " ".join(split_sentence)
    # put back the periods:
    clean_sent = re.sub("<prd>", ".", clean_sent)
    # place quote back in - TODO!
    # clean_sent = re.sub("<open_quote>", "<$", clean_sent)
    # clean_sent = re.sub("<close_quote>", ">$", clean_sent)
    return clean_sent

### This function iterates through a sentence list and applies the "clean_tokenized_sent()"
### function to each element in the list, returning a cleaned list of texts
def clean_tokenized_list(sent_list):
    cleaned_tokenized_sentences = []
    for sent in sent_list:
        clean_set = clean_tokenized_sent(sent)
        cleaned_tokenized_sentences.append(clean_set)
    return cleaned_tokenized_sentences


### This function takes a filename (output from transkribus) and formats it to a more convenient date-format
### that R can recognize during classification
def transform_newspaper_title(file_name):
    new_filename = file_name.split("-")[1:3]
    year = new_filename[0]
    month = new_filename[1][:3]
    formatted_month = dates_change.get(month)
    day = new_filename[1][3:]
    new_filename = f"{year}-{formatted_month}-{day}"
    return new_filename

# This is a legacy function which is now unused due to the expanded corpus with metadata.
def transform_novel_title(file_name):
    file_name_list = file_name.split("_")
    date = file_name_list.pop(-1).split(".")[0]
    new_filename = "_".join(file_name_list)
    return new_filename, date



### This is the primary cleaning and preprocessing function.
### It takes the output of input_corpus_of_txts() (a tuple of (FILE_NAME, TEXT)),
### applies preprocessing functions and outputs a pandas dataframe of the processed
### texts originally supplied to the function. 
def process_dirty_texts_to_df(corpora_of_filenames_and_dirty_texts):
    # creating an empty list to hold all the information from processing
    cleaned_texts = []
    # empty dictionary to transform into pandas dataframe
    cleaned_corpus_as_dictionary = {}
    # iterates over every file supplied
    for index, corpus in enumerate(corpora_of_filenames_and_dirty_texts):
        count = 0
        if index == 0:
            corpus_name = "Newspaper Corpus"
        elif index == 1:
            corpus_name = "Novels Corpus"
        print(f"\n[?] There are {len(corpus)} texts to process in {corpus_name}\n")
        for filename, dirtier_text in corpus:
            print(filename)
            progress(count, len(corpus))
            if index == 1:
                dirty_text, author, gender, date, source, is_newsnovel = remove_metadata(dirtier_text)
            elif index == 0:
                date = transform_newspaper_title(filename)
                dirty_text, author, gender, source, is_newsnovel = dirtier_text, "N/A", "N/A", "N/A", "N/A"
            # preprocesses the text
            preprocessed_text = preprocess_text(dirty_text, index)
            # tokenizes the text into sentences
            tokenized_sentences = sent_tokenize(preprocessed_text)
            # cleans the list of tokenized sentences
            cleaned_tokenized_sentences = clean_tokenized_list(tokenized_sentences)
            # setting up a relative_sentence_index to capture the location
            # of each sentence within their respective files
            relative_sentence_index = 0
            # iterate over every individual sentence within the cleaned and tokenized sentence
            # (each sentence in a single document)
            for clean_tokenized_sentence in cleaned_tokenized_sentences:
#                if index == 0:
#                    # if this is the newspaper corpus, transform the dates to R-readable format
#                    date = transform_newspaper_title(filename)
#                    new_filename = filename
#                elif index == 1:
#                    new_filename, date = transform_novel_title(filename)
                # creates a tuple of all the information we'd like to see in the dataframe
                tupled_files = (filename, date, author, gender, source, clean_tokenized_sentence, relative_sentence_index, index, is_newsnovel)
                # adds them to our empty list above (cleaned_texts)
                cleaned_texts.append(tupled_files)
                # increments the relative sentence index
                relative_sentence_index += 1
            count += 1
        progress(100, 100)
    # each tuple element is assigned as a value in the empty dictionary defined above
    cleaned_corpus_as_dictionary['file_name'] = [x[0] for x in cleaned_texts]
    cleaned_corpus_as_dictionary['text_date'] = [x[1] for x in cleaned_texts]
    cleaned_corpus_as_dictionary['author'] = [x[2] for x in cleaned_texts]
    cleaned_corpus_as_dictionary['gender'] = [x[3] for x in cleaned_texts]
    cleaned_corpus_as_dictionary['source'] = [x[4] for x in cleaned_texts]
    cleaned_corpus_as_dictionary['sentences'] = [x[5] for x in cleaned_texts]
    cleaned_corpus_as_dictionary['relative_sentence_index'] = [x[6] for x in cleaned_texts]
    cleaned_corpus_as_dictionary['newspaper_0_novel_1'] = [x[7] for x in cleaned_texts]
    cleaned_corpus_as_dictionary['news_novel'] = [x[8] for x in cleaned_texts]

    # create df from dictionary
    df = pd.DataFrame(cleaned_corpus_as_dictionary)
    
    print("\n[-] Text preprocessing completed.")
    return df
