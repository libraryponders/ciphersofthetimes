# pos functions
from utility_code import *
import spacy

# faster but less accurate model:
# nlp = spacy.load("en_core_web_sm")
# slower but more accurate model:
# download it first
# !python -m spacy download en_core_web_lg

nlp = spacy.load("en_core_web_lg")

def get_pos_counts_from_tagged_sentence(analyzed_sent):
    pos_counts = []
    pos_counts_raw = analyzed_sent.count_by(spacy.attrs.IDS['POS'])
    for pos, count in pos_counts_raw.items():
        tag = analyzed_sent.vocab[pos].text
        pos_count = (tag, count)
        pos_counts.append(pos_count)
    # return a list of pos_counts
    return pos_counts

def pos_tag_sentence(sent):
    tagged_sentence = []
    analyzed_sent = nlp(sent, disable = ['ner'])
    # getting the complete tokenized sentence
    for token in analyzed_sent:
        tagged_word = (token, token.pos_)
        tagged_sentence.append(tagged_word)
    pos_counts = get_pos_counts_from_tagged_sentence(analyzed_sent)
    # return a tuple of both
    return (tagged_sentence, pos_counts)

def pos_tag_list_of_sentences(list_of_cleaned_sentences):
    pos_tagged_text = []
    for sent in list_of_cleaned_sentences:
        tagged_sent = pos_tag_sentence(sent)
        pos_tagged_text.append(tagged_sent)
    # returns a list of tuples
    return pos_tagged_text


def pos_tag_texts_from_df(df, sentences_column='sentences'):
    df['tagged_sentences'] = ''
    df['pos_counts'] = ''
    for index, row in df.iterrows():
        progress(index, len(list(df.index.values)))
        sentence = row[sentences_column]
        tagged_sentence, pos_counts = pos_tag_sentence(sentence)
        df.at[index, 'tagged_sentences'] = tagged_sentence
        df.at[index, 'pos_counts'] = pos_counts
        # print(tagged_sentence)
        # if index >= 10:
        #     break
    return df
