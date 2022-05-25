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

# this function takes in a tuple of two lists, 
# tagged_sentence and pos_counts
# and checks for sequential occurences of title + name
# if it finds them, it edits the two lists,
# assigning the title to the proper noun after it,
# and adjusting the pos_counts to reflect the change
def remove_double_propernouns_from_tagged_sentence(tagged_sentence_and_counts):
    # breaking apart our tuple into two lists
    tagged_sentence, pos_counts = tagged_sentence_and_counts
    # setting up a list of indexes to remove
    indexes_to_remove = []
    for index, tagged_word in enumerate(tagged_sentence):
        # try is necessary here since we change the value of the next index before reaching it
        # because we change it from a token to a string, the ".text" method no longer works on the new
        # word. If we catch this attributeError, we just continue, since we know that that word has been edited
        try:
            # checks that the tag is PROPN and that the word itself is a title
            if ((tagged_word[1] == "PROPN") and (tagged_word[0].text in titles)):
                # checks that the following word is also a proper noun
                if tagged_sentence[index + 1][1] == "PROPN":
                    # if so, get the title, and create a new value for the proceeding proper noun
                    # with the title + white space + name
                    # then place it back at it's proper index with the new values
                    # and keep the index where we are at in a list, to remove them after
                    identified_title = tagged_word[0].text
                    new_proper_noun = identified_title + " " + tagged_sentence[index + 1][0].text # the next word in list
                    tagged_sentence[index + 1] = (new_proper_noun, "PROPN")
                    indexes_to_remove.append(int(index))

        except AttributeError:
            # Means that we've already changed that title since it's no longer a spacy token type
            # so we should continue the loop
            continue
            
    # first check if anything was removed in the sentence:
    if len(indexes_to_remove) > 0:
        number_of_titles_joined_to_names = len(indexes_to_remove)
        # if something was, we remove values from the PROPN count
        # equal to the number of changes made to the sentence
        for index, pos_count in enumerate(pos_counts):
            if pos_count[0] == "PROPN":
                new_value = pos_count[1] - number_of_titles_joined_to_names
                new_tuple = (pos_count[0], new_value)
                # place new value back into list at index with the new tuple
                pos_counts[index] = new_tuple
                break
        # finally, we create a new list of the tagged words with only the indexes NOT in our "to_remove" list
        tagged_sentence = [tagged_word for index, tagged_word in enumerate(tagged_sentence) if index not in indexes_to_remove]
    # and we return the new values
    return (tagged_sentence, pos_counts)

def pos_tag_texts_from_df(df, sentences_column='sentences'):
    df['tagged_sentences'] = ''
    df['pos_counts'] = ''
    for index, row in df.iterrows():
        progress(index, len(list(df.index.values)))
        sentence = row[sentences_column]
        tagged_sentence_and_counts = pos_tag_sentence(sentence)
        tagged_sentence, pos_counts = remove_double_propernouns_from_tagged_sentence(tagged_sentence_and_counts)
        df.at[index, 'tagged_sentences'] = tagged_sentence
        df.at[index, 'pos_counts'] = pos_counts
    return df
