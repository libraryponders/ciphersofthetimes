import pandas as pd
from lexical_diversity import lex_div as ld
import string
import math
import numpy as np
from pandas_profiling import ProfileReport

df = pd.read_csv('./news_df.csv', index_col=0).convert_dtypes()

# assign length in characters
df["len_in_chars"] = 0
for index, row in df.iterrows():
    text = row["text_"]
    df.at[index, "len_in_chars"] = len(text)

# get a dictionary of filenames as keys and list of indexes as values
indexes_file_name = []
file_names_and_indexes = {}
for index, row in df.iterrows():
    file_name = row["file_names"]
    if index == 0:
        prev_file_name = file_name
    elif index == df.index[-1]:
        indexes_file_name.append(index)
        file_names_and_indexes[prev_file_name] = indexes_file_name
        break
    if file_name == prev_file_name:
        indexes_file_name.append(index)
    else:
        file_names_and_indexes[prev_file_name] = indexes_file_name
        indexes_file_name = []
        indexes_file_name.append(index)
    prev_file_name = file_name


# assign cumulative length per issue in chars for each sentence
total_len = 0
df["cumulative_len_in_chars"] = 0
for index, row in df.iterrows():
    file_name = row["file_names"]
    len_in_chars = row["len_in_chars"]
    if index == 0:
        prev_file_name = file_name
    if file_name != prev_file_name:
        total_len = 0
    total_len += len_in_chars
    df.at[index, "cumulative_len_in_chars"] = total_len
    prev_file_name = file_name


# use the cumulative length with the created dictionary to divide the total
# length in characters in two, then using that information to tag sentences
# as part of df_1 or df_2
df["df_1_or_2"] = 0
for file_name in file_names_and_indexes.keys():
    indexes = file_names_and_indexes[file_name]
    cum_value_of_last = df.loc[indexes[-1], "cumulative_len_in_chars"]
    half_length = round(cum_value_of_last / 2)
    for index in indexes:
        row_cumulative_len_in_chars = df.loc[index, "cumulative_len_in_chars"]
        if row_cumulative_len_in_chars <= half_length:
            df.at[index, "df_1_or_2"] = 1
        elif row_cumulative_len_in_chars > half_length:
            df.at[index, "df_1_or_2"] = 2
        else:
            print(
                f"problem with i {index} - row_cumulative_len_in_chars is {row_cumulative_len_in_chars}")

# split df into two based on the above tags
news_df_first_half = df[df['df_1_or_2'] == 1]
news_df_second_half = df[df['df_1_or_2'] == 2]

# generate reports for both dataframes
dfs = []
dfs.append(news_df_first_half)
dfs.append(news_df_second_half)
for i, df in enumerate(dfs):
    print(f"shape of df_{i + 1}: {df.shape}")
    df.to_csv(f"news_df_{i + 1}.csv")
    prof = ProfileReport(df)
    prof.to_file(output_file=f'news_df_report_{i + 1}.html')

