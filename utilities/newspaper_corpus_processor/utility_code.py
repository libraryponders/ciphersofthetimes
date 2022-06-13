### This file contains utility functions for the newspaper processor.

# imports:
import sys
import pandas as pd
import random
import os
import codecs

### Progress bar to view the progress of lengthy processes
### As suggested by Rom Ruben 
### (see: http://stackoverflow.com/questions/3173320/text-progress-bar-in-the-console/27871113#comment50529068_27871113)
def progress(count, total, status=''):
    bar_len = 60
    filled_len = int(round(bar_len * count / float(total)))
    percents = round(100.1 * count / float(total), 1)
    bar = '#' * filled_len + '-' * (bar_len - filled_len)
    sys.stdout.write('[%s] %s%s ...%s\r' % (bar, percents, '%', status))
    sys.stdout.flush() 


def get_sample_newspapers(path_to_newspapers, sample_number):
    years_months_days = []
    sample_newspapers = []
    # first get a list of all the file dates
    for filename in os.listdir(path_to_newspapers):
        # double check that these are text files
        if filename.endswith(".txt"):
            newspaper_date = filename.split(".txt")[0]
            try:
                years_months_days.append(tuple(newspaper_date.split("-")))
            except Exception as e:
                print(f"File {newspaper_date} is not formatted properly. Files should look like: YYYY-MM-DD.txt")
    # get random days of each month
    years = [date[0] for date in years_months_days]
    unique_years = list(set(years))
    months = [date[1] for date in years_months_days]
    unique_months = list(set(months))

    for unique_year in unique_years:
        for unique_month in unique_months:
            days_in_month = [date[2] for date in years_months_days if (date[1] == unique_month) and (date[0] == unique_year)]
            try:
                selected = random.sample(days_in_month, sample_number)
            # a ValueError indicates that there weren't enough newspaper dates in the corpus,
            # and that the sample number provided is greater than the amount of issues
            # for those months and years
            except ValueError():
                while sample_number > 0:
                    sample_number -= 1
                    try:
                        selected = random.sample(days_in_month, sample_number)
                    except ValueError():
                        continue
            for date in selected:
                new_date = f"{unique_year}-{unique_month}-{date}.txt"
                # print(new_date)
                sample_newspapers.append(new_date)
    return sample_newspapers

### Function to save the dataframe to a csv file.
### It requires the dataframe to save, the path to save it to,
### and a file name. Default is None since file name can be provided from the command line as well.
def output_full(df, path_to_spreadsheets, output_file_name=None):
    if output_file_name == None:
        spreadsheet_name = input("[=] Please input desired spreadsheet name (full df): ")
    else:
        spreadsheet_name = output_file_name
    df.to_csv(path_to_spreadsheets + spreadsheet_name + '_full.csv')
    print(spreadsheet_name + ' was saved in '+str(path_to_spreadsheets) + f" as {spreadsheet_name}_full.csv\n")

### Function to save the metadata of the dataframe to a csv file.
### It is identical to the output_full function except that it also considers a list
### of columns not to save. 
def output_meta(df, path_to_spreadsheets, output_file_name=None):
    if output_file_name == None:
        spreadsheet_name = input("[=] Please input desired spreadsheet name (meta df): ")
    else:
        spreadsheet_name = output_file_name
    list_of_columns_not_to_include = ['sentences']
    columns_to_include = [column_name for column_name in df.columns.values.tolist() if column_name.lower() not in list_of_columns_not_to_include]
    df_meta = df[columns_to_include]
    df_meta.to_csv(path_to_spreadsheets + spreadsheet_name + '_meta.csv')
    print(spreadsheet_name + ' was saved in '+str(path_to_spreadsheets) + f" as {spreadsheet_name}_meta.csv\n")

### This function takes in a dataframe of sentences organized as a "tidy text" format 
### and transforms it into a dataframe of words organized as a "tidy text" format.
### It also adds an additional "relative_word_index" for easy representation of where the
### word is within the sentence. 
def documents_as_sentences_to_documents_as_words(df):
    df_as_words_list = []
    word_tokenized_corpus_as_dictionary = {}
    # iterates over the entire dataframe, grabbing individual words and tags
    # and creating a new tuple of lists with their information and increments the word index
    for index, row in df.iterrows():
        progress(index, len(df.index))
        tagged_sentence = row["tagged_sentences"]
        sentence_index = row["relative_sentence_index"]
        filename = row["file_names"]
        relative_word_index = 0
        for word, tag in tagged_sentence:
            tupled_files = (filename, sentence_index, relative_word_index, word, tag)
            df_as_words_list.append(tupled_files)
            relative_word_index += 1
    # lists are ultimately transformed into values within a python dictionary and transformed into a dataframe
    word_tokenized_corpus_as_dictionary['file_names'] = [x[0] for x in df_as_words_list]
    word_tokenized_corpus_as_dictionary['relative_sentence_index'] = [x[1] for x in df_as_words_list]
    word_tokenized_corpus_as_dictionary['relative_word_index'] = [x[2] for x in df_as_words_list]
    word_tokenized_corpus_as_dictionary['words_'] = [x[3] for x in df_as_words_list]
    word_tokenized_corpus_as_dictionary['tags_'] = [x[4] for x in df_as_words_list]

    df = pd.DataFrame(word_tokenized_corpus_as_dictionary)
    print("\n[-] Completed transforming dataframe into word-based tidy text format")
    return df

### Takes in a path and returns a list of tuples in the format (FILE_NAME, TEXT)
def import_corpus_from_path(path):
    list_of_filenames_and_dirty_texts = []
    for file_name in os.listdir(path):
        # double check that these are text files
        if file_name.endswith(".txt"):
            with codecs.open(path + file_name, 'r', encoding='utf-8', errors="ignore") as raw_text:
                dirty_text = raw_text.read()
            standardized_file_name = file_name.replace(" ", "_")
            list_of_filenames_and_dirty_texts.append((standardized_file_name, dirty_text))
    return list_of_filenames_and_dirty_texts

### Imports a corpus from a path and a list of file_names
def import_corpus_from_path_and_file_names(path, file_names):
    list_of_filenames_and_dirty_texts = []
    for file_name in file_names:
        with codecs.open(path + file_name, 'r', encoding='utf-8', errors="ignore") as raw_text:
            dirty_text = raw_text.read()
        standardized_file_name = file_name.replace(" ", "_")
        list_of_filenames_and_dirty_texts.append((standardized_file_name, dirty_text))
    return list_of_filenames_and_dirty_texts

### Imports multiple corpora (both novels and newspapers) by using a list of paths
### and an optional list_of_sample_newspapers. If a list of samples is provided,
### the function will return only those files listed
def import_corpora(paths_to_corpora, list_of_sample_newspapers=None):
    dirty_texts = []
    path_newspaper_corpus = paths_to_corpora[0]
    path_novel_corpus = paths_to_corpora[1]
    if list_of_sample_newspapers != None:
        dirty_texts.append(import_corpus_from_path_and_file_names(path_newspaper_corpus, list_of_sample_newspapers))
    else:
        dirty_texts.append(import_corpus_from_path(path_newspaper_corpus))
    dirty_texts.append(import_corpus_from_path(path_novel_corpus))
    return dirty_texts