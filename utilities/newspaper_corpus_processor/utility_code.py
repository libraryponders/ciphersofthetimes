### This file contains utility functions for the newspaper processor.

# imports:
import sys
import pandas as pd

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