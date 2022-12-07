### This file contains POS-related functions run on the newspaper corpus after
### running preprocessing. POS-tagging is done with spacy.

# imports
from utility_code import *
import multiprocessing, spacy


### Remember to download it first. If using Jupyter Notebooks, add
### an exclamation mark before "python." To download: "python -m spacy download en_core_web_lg"

### Setting up titles in order to condense multiple PROPN (proper nouns)
### into singular instances. Example: (Mr., PROPN), (Smith, PROPN) -> (Mr. Smith, PROPN)
titles = ["Mr.", "St.", "Mrs.", "Ms.", "Dr.", "Esq.", "Sec.", "Secretar."]
sentence_end_symbols = [".", ",", "?", "!"]
nlp = spacy.load("en_core_web_lg")

### This function takes in an analyzed sentence (already tagged by the pos_tag_sentence function)
### and returns a counted list of all the POS tags in that sentence. 
### Example -> [('PROPN', 2), ('VERB', 1), ('ADV', 1), ('PUNCT', 1)]
def get_pos_counts_from_tagged_sentence(analyzed_sent):
    pos_counts = []
    # changing ["TAG"] to ["POS"] will change the format of the tags from a granular
    # identification, such as "past-tense verb," to a universal tagger, such as simply "VERB"
    pos_counts_raw = analyzed_sent.count_by(spacy.attrs.IDS['TAG'])
    for pos, count in pos_counts_raw.items():
        tag = analyzed_sent.vocab[pos].text
        pos_count = (tag, count)
        pos_counts.append(pos_count)
    return pos_counts

### This function tags each sentence. NER is currently disabled to speed up processing times.
### It takes in a cleaned sentence and returns a tuple of (TAGGED_SENTENCE, POS_COUNTS_IN_SENTENCE),
### using the get_pos_counts_from_tagged_sentence() function.
def pos_tag_sentence(sent):
    tagged_sentence = []
    analyzed_sent = nlp(sent, disable = ['ner'])
    # getting the complete tokenized sentence
    for token in analyzed_sent:
        tagged_word = (token, token.pos_)
        tagged_sentence.append(tagged_word)
    pos_counts = get_pos_counts_from_tagged_sentence(analyzed_sent)
    return (tagged_sentence, pos_counts)

### This is a helper function for pos_tag_sentence(). It simple applies the logic
### of that function to a list by iterating over it and returning a new list
### of only cleaned sentences. It is not currently used, since the POS tagging
### happens after the dataframe is created, in which case the sentences are already
### defined as seperate rows, and there is no need to gather them as a list.
def pos_tag_list_of_sentences(list_of_cleaned_sentences):
    pos_tagged_text = []
    for sent in list_of_cleaned_sentences:
        tagged_sent = pos_tag_sentence(sent)
        pos_tagged_text.append(tagged_sent)
    # returns a list of tuples
    return pos_tagged_text



### This function uses the "titles" list defined at the top of this file
### to transform all occurences of names receiving two PROPN tags into one occurence. 
### Example: (Mr., PROPN), (Smith, PROPN) -> (Mr. Smith, PROPN).
### It serves as an intermediary function between pos_tag_sentence() and pos_tag_texts_from_df()
### It takes in the tuple created by pos_tag_sentence(), which contains (TAGGED_SENTENCE, POS_COUNTS_IN_SENTENCE)
### then verifies that all names become one PROPN in that sentence, then creates a new tuple 
### and passes it to pos_tag_texts_from_df(), where it is placed in the dataframe. It also adjusts POS_COUNTS_IN_SENTENCE
### to reflect the change to the tagged sentence.
def remove_double_propernouns_from_tagged_sentence(tagged_sentence_and_counts):
    # breaking apart tuple into two lists
    tagged_sentence, pos_counts = tagged_sentence_and_counts
    # setting up a list of indexes to remove
    indexes_to_remove = []
    for index, tagged_word in enumerate(tagged_sentence):
        # try is necessary here since we change the value of the next index before reaching it.
        # as we change it from a spacy token to a string, the ".text" value no longer exists in the new
        # word. if we catch this attributeError, we skip the current iteration, since we know that that word has been edited
        try:
            # checks that the tag is PROPN and that the word itself is a title
            if ((tagged_word[1] == "PROPN") and (tagged_word[0].text in titles)):
                # checks that the following word is also a proper noun
                if len(tagged_sentence) > (index + 1) and tagged_sentence[index + 1][1] == "PROPN":
                    # if so, get the title, and create a new value for the proceeding proper noun
                    # with the format "title + white space + name"
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

    # now we change the pos_counts (if necessary)
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
                # we can break here since we aren't changing any other pos_count
                break
        # lastly, we create a new list of the tagged words with only the indexes NOT in our "to_remove" list
        tagged_sentence = [tagged_word for index, tagged_word in enumerate(tagged_sentence) if index not in indexes_to_remove]
    # and we return the new values
    return (tagged_sentence, pos_counts)

### This function applies the POS tagging processing to a single row. It is used
### in conjunction with pos_tag_texts_from_df to allow for multiprocessing.
def pos_tag_single_line(iterrows_data):
    index, row = iterrows_data
    # show progress bar since this can take some time
    progress(index, len(list(df.index.values)))
    # grab the text column specified by the function
    sentence = row['sentences']
    # pos tag the sentence
    tagged_sentence_and_counts = pos_tag_sentence(sentence)
    # then check for double PROPN tags as a result of proper names
    tagged_sentence, pos_counts = remove_double_propernouns_from_tagged_sentence(tagged_sentence_and_counts)
    # place the output in their appropriate column at the correct index
    df.at[index, 'tagged_sentences'] = tagged_sentence
    df.at[index, 'pos_counts'] = pos_counts
    

### This function takes in the dataframe outputted by process_dirty_texts_to_df()
### and applies all the POS tagging processing to the individual rows. A "sentences_column"
### should also be supplied (default is 'sentences') so that the function knows
### what text column to analyze.
def pos_tag_texts_from_df(df, sentences_column='sentences'):
    # setting up two new empty df columns for the pos-tagged texts
    df['tagged_sentences'] = ''
    df['pos_counts'] = ''
    pool = multiprocessing.Pool()
    pool.map(pos_tag_single_sentence, df.iterrows())
    return df


### This function reformats the tagged sentence tuple into a format
### comfortable for Ronny to run tidy text formatting
def format_for_tidy_text_prep(tagged_sentence):
    text_ = ""
    tags_ = ""
    for word in tagged_sentence:
        tags_ = tags_ + " " + word[1]
        if str(word[0]) in sentence_end_symbols:
            text_ += str(word[0])
        else:
            text_ = text_ + " " + str(word[0])
    return (text_, tags_)


def pos_tag_texts_from_df_new(df, sentences_column='sentences'):
    # setting up two new empty df columns for the pos-tagged texts
    df['text_'] = ''
    df['tags_'] = ''
    # iterate over df
    for index, row in df.iterrows():
        # show progress bar since this can take some time
        progress(index, len(list(df.index.values)))
        # grab the text column specified by the function
        sentence = row[sentences_column]
        # pos tag the sentence
        tagged_sentence_and_counts = pos_tag_sentence(sentence)
        # then check for double PROPN tags as a result of proper names
        tagged_sentence, pos_counts = remove_double_propernouns_from_tagged_sentence(tagged_sentence_and_counts)
        # get text in a pre-tidy text format for Ronny
        text_as_string, pos_counts_as_string = format_for_tidy_text_prep(tagged_sentence)
        # place the output in their appropriate column at the correct index
        df.at[index, 'text_'] = text_as_string
        df.at[index, 'tags_'] = pos_counts_as_string
    progress(100, 100)
    return df
