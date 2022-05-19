# cleaning functions

# required imports:
import codecs
from nltk.tokenize import sent_tokenize
import os
import pandas as pd
import re
import unicodedata

# project functions:
from utility_code import *

### regex:

regex_expressions = {"initials": r"\b([A-Z][.](\s)?)+", "prefixes": r"(Mr|St|Mrs|Ms|Dr|Esq|Sec|Secretar)[.]",\
                     "addresses": "", "dates": "", "line_break": r"¬\n", "space": r"/s",\
                     "dashes": r"[-]+", "quote_marks": r"(“|”)", \
                     "months_abrv": r"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[.](\s*(\d{1,2})(,|\.)?)?(\s*\d+)?",\
                     "pennies": r"(\d+[.]?\s*)[d][.]", "months_and_years": r"\d{1,2}[.]\s*(\d{4})"}


def input_corpus_of_txts(path):
    list_of_filenames_and_dirty_texts = []
    for filename in os.listdir(path):
        with codecs.open(path + filename, 'r', encoding='utf-8', errors="ignore") as raw_text:
            dirty_text = raw_text.read()
        list_of_filenames_and_dirty_texts.append((filename, dirty_text))
    return list_of_filenames_and_dirty_texts


# strip all accented characters:
def strip_accents(text):
    text = unicodedata.normalize('NFD', text).encode('ascii', 'ignore').decode("utf-8")
    return str(text)

def process_periods(text):
    # no matchobj needed since this is only called in other processing functions
    text = re.sub(r"[.]","<prd>", text)
    return text

def process_periods_to_commas(matchobj):
    text = matchobj.group(0)
    text = re.sub(r"[.]", ",", text)
    return text

# processing functions for regex calls in preprocess_text() function
# process initials for regex, and return a format that we can identify
def process_initials(matchobj):
    text = matchobj.group(0)
    text = process_periods(text)
    text = re.sub(r"\s*", "", text)
    text = text + " "
    return text

def process_months_abrv(matchobj):
    text = matchobj.group(0)
    text = process_periods(text)
    # text = " <date>"+text+"<date> "
    return text

def process_pennies(matchobj):
    text = matchobj.group(0)
    text = re.sub(r"d[.]?","pennies", text)
    text = process_periods(text)
    return text

# combine it together
def preprocess_text(text):
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
    text = re.sub(regex_expressions["quote_marks"], '"', text)
    # strip all pennies "XX d." in the text:
    text = re.sub(regex_expressions["pennies"], process_pennies, text)
    # strip all accents from the text:
    text = strip_accents(text)
    # print("[-] Finished processing linebreaks, initials, prefixes, months, years, numbers, dashes, quotations marks, and pennies symbols...")
    return text

def clean_tokenized_sent(sent):
    # removing newline notations
    clean_sent = re.sub('\n', ' ', sent)
    clean_sent = re.sub('\r', ' ', clean_sent)
    # transforming multiple spaces to one space
    clean_sent = re.sub('\s+',' ', clean_sent)
    split_sentence = clean_sent.split()
    
    # transform all the words that are completely uppercase to lowercase
    for index, word in enumerate(split_sentence):
        if (word.isupper()):
            new_word = word.lower()
            split_sentence[index] = new_word
    clean_sent = " ".join(split_sentence)
    
    # put back the periods:
    clean_sent = re.sub("<prd>", ".", clean_sent)
    # clean_sent = clean_sent.lower()
    return clean_sent

### Not needed if done in df
def clean_tokenized_list(sent_list):
    cleaned_tokenized_sentences = []
    for sent in sent_list:
        clean_set = clean_tokenized_sent(sent)
        cleaned_tokenized_sentences.append(clean_set)
    return cleaned_tokenized_sentences

def process_dirty_texts_to_df(list_of_filenames_and_dirty_texts):
    print("[-] Beginning text preprocessing...")
    filenames = []
    cleaned_texts = []
    cleaned_corpus_as_dictionary = {}
    for index, (filename, dirty_text) in enumerate(list_of_filenames_and_dirty_texts):
        progress(index, len(list_of_filenames_and_dirty_texts))
        preprocessed_text = preprocess_text(dirty_text)
        tokenized_sentences = sent_tokenize(preprocessed_text)
        cleaned_tokenized_sentences = clean_tokenized_list(tokenized_sentences)
        for clean_tokenized_sentence in cleaned_tokenized_sentences:
            filenames.append(filename)
            cleaned_texts.append(clean_tokenized_sentence)
    cleaned_corpus_as_dictionary['file_names'] = filenames
    cleaned_corpus_as_dictionary['sentences'] = cleaned_texts
    
    df = pd.DataFrame(cleaned_corpus_as_dictionary)
    print("\n[-] Text preprocessing completed.")
    return df