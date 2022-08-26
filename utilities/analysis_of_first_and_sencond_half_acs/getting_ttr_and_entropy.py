import pandas as pd
from lexical_diversity import lex_div as ld
import string
import math
import numpy as np
from pandas_profiling import ProfileReport
import os

# converters for df
# region:       -- functions


def convert_dtype(x):
    if not x:
        return ''
    try:
        return str(x)
    except:
        return ''


def calc_entropy(s):
    # Letter Frequency Chart for English
    freq = {
        'E': 0.1202, 'T': 0.091, 'A': 0.0812, 'O': 0.0768, 'I': 0.0731,
        'N': 0.0695, 'S': 0.0628, 'R': 0.0602, 'H': 0.0592, 'D': 0.0432,
        'L': 0.0398, 'U': 0.0288, 'C': .0271, 'M': 0.0261, 'F': 0.023,
        'Y': 0.0211, 'W': 0.0209, 'G': 0.0203, 'P': 0.0182, 'B': 0.0149,
        'V': 0.0111, 'K': 0.0069, 'X': 0.0017, 'Q': 0.0011, 'J': 0.001,
        'Z': 0.0007
    }
    ascii_range = (65, 90)

    # Ensure the string's case matches the dictionary keys
    s = s.upper()
    # Using the frequency of a letter as p(x), calculate entropy of the string using the formula:
    # H = [sum of (-log[p(x)]_2)] / len(s)
    total_entropy = 0
    for c in s:
        # Only compute for values of A-Z
        if(ord(c) >= ascii_range[0] and ord(c) <= ascii_range[1]):
            total_entropy += -math.log(freq[c], 2)

    total_entropy = total_entropy / len(s)

    return total_entropy


def print_info(column_name):
    print(f"[!] {column_name.upper()}: AVG = {news_df[column_name].mean()}\tMIN= {news_df[column_name].min()}\tMAX= {news_df[column_name].max()}")
# endregion:       -- functions

os.system('rm ./logs/*')
df = pd.read_csv('./data/60_novels_1860-1879_newspapers_spreadsheets_spacy_3_4_full.csv',
                 index_col=0).convert_dtypes()

novels_df = df[df['newspaper_0_novel_1'] == 1].copy()
news_df = df[df['newspaper_0_novel_1'] == 0].copy()
del df

print("[+] Beginning metadata collection")
print("[+] Assigning TTRs, entropy, and sentence length")
news_df["ttr_"] = 0.0
news_df["entropy_"] = 0.0
news_df['sentence_length'] = 0
indexes_to_remove = []
for index, row in news_df.iterrows():
    sentence_raw = row['text_']
    sentence = sentence_raw.translate(
        str.maketrans('', '', string.punctuation))
    try:
        entropy_ = calc_entropy(sentence)
        news_df.at[index, 'entropy_'] = entropy_
    except ZeroDivisionError as e:
        # print(f"ZDE spotted at row {index}. sentence: {sentence_raw}")
        indexes_to_remove.append(index)
        with open('logs/zero_division.txt', 'a') as f:
            f.write(f"{index}|{sentence_raw}\n")
    sentence = sentence.split()
    ttr_ = ld.ttr(sentence)
    news_df.at[index, 'ttr_'] = ttr_
    news_df.at[index, 'sentence_length'] = len(sentence)

news_df.head(20)

print("[+] Before dropping entropy 0 and zero division errors for TTR")
print_info('entropy_')
print_info('ttr_')
print_info('sentence_length')
print()

entropy_zero = []
for index, row in news_df.iterrows():
    entropy_ = row["entropy_"]
    sentence_raw = row["text_"]
    if (entropy_ == 0.0):
        log_line = f"{index}|{sentence_raw}\n"
        with open('logs/entropy_zero.txt', 'a') as f:
            f.write(log_line)
        entropy_zero.append(index)

to_remove_all = indexes_to_remove + entropy_zero
# news_df = news_df.drop(to_remove_all)
# remove sentences with only punctuation
# news_df =  news_df.drop(indexes_to_remove)

# remove sentences with only numbers
# news_df =  news_df.drop(entropy_zero)

print("[+] After dropping entropy 0")
print_info('entropy_')
print_info('ttr_')
print_info('sentence_length')
print()

entropy_under_2_5 = []
entropy_over_4_5 = []
ttr_under_0_3 = []
for index, row in news_df.iterrows():
    ttr_ = row["ttr_"]
    entropy_ = row["entropy_"]
    sentence_raw = row["text_"]
    # entropys
    if (entropy_ < 2.5):
        entropy_under_2_5.append((index, entropy_, sentence_raw))
        with open('logs/entropy_under_2_5.txt', 'a') as f:
            f.write(f"{index} | {entropy_} | {sentence_raw}\n")
    if (entropy_ > 4.5):
        entropy_over_4_5.append((index, entropy_, sentence_raw))
        with open('logs/entropy_over_4_5.txt', 'a') as f:
            f.write(f"{index} | {entropy_} | {sentence_raw}\n")
    # ttrs
    if (ttr_ < 0.3):
        ttr_under_0_3.append((index, ttr_, sentence_raw))
        with open('logs/ttr_under_0_3.txt', 'a') as f:
            f.write(f"{index} | {ttr_} | {sentence_raw}\n")


# df_columns = ['file_names', 'text_dates', 'sentences', 'relative_sentence_index',
#               'newspaper_0_novel_1', 'text_', 'tags_', 'ttr_', 'entropy_']

sentence_length_array = news_df['sentenc> e_length'].to_numpy()
ttr_array = news_df['ttr_'].to_numpy()
entropy_array = news_df['entropy_'].to_numpy()

news_df.to_csv(f"news_df_ttr_entropy.csv")
# get report
prof = ProfileReport(news_df)
prof.to_file(output_file='report.html')
