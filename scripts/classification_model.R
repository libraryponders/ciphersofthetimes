# PACKAGES ---------------------------------------------------------------------

library(tidyverse)
library(textrecipes)
library(tidymodels)
library(discrim)
library(naivebayes)
library(tokenizers)
library(tidytext)
library(coop)
library(glmnet)
library(vip)

# DATA INPUT -------------------------------------------------------------------

corpus_output <- read_csv("corpora/processed_corpus_meta.csv") #input data

corpus_output <- corpus_output %>%
  rename(index = "...1", #rename columns
         tag = tags_,
         text = text_,
         pub_year = text_date,
         corpus = newspaper_0_novel_1)

glimpse(corpus_output) #check columns headers

#correct for spaces between words prior to tokenization and to match unique POS tagging (PROPN)
{corpus_output$tags <- gsub('PUNCT','', corpus_output$tag)
  corpus_output$text <- gsub('Mr. ','Mr.',corpus_output$text)
  corpus_output$text <- gsub('Mrs. ','Mrs.',corpus_output$text)
  corpus_output$text <- gsub('Ms. ','Mr.',corpus_output$text)
  corpus_output$text <- gsub('St. ','St.',corpus_output$text)
  corpus_output$text <- gsub('Dr. ','Dr.',corpus_output$text)
  corpus_output$text <- gsub('Esq. ','Esq.',corpus_output$text)
  corpus_output$text <- gsub('Sec. ','Sec.',corpus_output$text)
  corpus_output$text <- gsub('Secretar. ','Secretar.',corpus_output$text)}

#remove any double spaces in between text and tags 
corpus_output <- corpus_output %>% 
  mutate(text = str_replace_all(text, "  ", " ")) %>% 
  mutate(tag = str_replace_all(tag, "  ", " "))

#rename corpus column and convert to class 'factor'
corpus2class <- corpus_output %>%
  mutate(corpus = factor(case_when(corpus == "0" ~ "newspaper", #newspapers observed as 0 in corpus output
                                   corpus == "1" ~ "novel"))) #novels observed as 1 in corpus output

#set newspaper observation to NA for columns that only apply to novels
{corpus2class$gender <- ifelse(corpus2class$corpus == "newspaper", NA, corpus2class$gender)
  corpus2class$author <- ifelse(corpus2class$corpus == "newspaper", NA, corpus2class$author)
  corpus2class$source <- ifelse(corpus2class$corpus == "newspaper", NA, corpus2class$source)
  corpus2class$news_novel <- ifelse(corpus2class$corpus == "newspaper", NA, corpus2class$news_novel)}

# FILTERING --------------------------------------------------------------------
titles <- corpus2class %>% #filter title names
  filter(corpus == "novel") %>%
  group_by(pub_year, news_novel) %>%
  mutate(title = str_replace_all(file_name, "_", " ")) %>% 
  mutate(title = str_replace_all(title, ".txt", "")) %>% 
  summarise(title = unique(title))
titles$pub_year <- as.numeric(titles$pub_year) #year from character to numeric

#cast as tidy, tokenized data frame
newspaper_output_tidy <- corpus2class %>% #newspaper corpus
  filter(corpus == "newspaper") %>%
  pivot_longer(cols = 10:11, #split text from feature
               names_to = "feature",
               values_to = "text") %>%
  unnest_tokens(text, 
                text,
                strip_punct = FALSE) %>% #unnest words from text string
  ungroup() %>%
  group_by(index, feature) %>%
  mutate(row = row_number()) %>%
  pivot_wider(names_from = feature, #create two columns, one for tags and one for text
              values_from = text) %>%
  select(-row)

newspaper_output_tidy$year <- #format year column to an object of date class
  format(as.Date(newspaper_output_tidy$pub_year,
                 format="%Y-%m-%d"),
         "%Y")

mistagged_sentences_news <- newspaper_output_tidy %>% #save mis-tagged sentences as a list
  filter(tag == "x" |
           is.na(tag)) %>% #filter for words/phrases where POS tagging failed ('x' tagged or NA)
  as.list(index) #add to list object

#remove sentences with at least one mistagged word
corpus2class_clean <- corpus2class[ ! corpus2class$index %in% #remove sentences based on index value
                                      mistagged_sentences_news$index, ]

newspaper_output_tidy_clean <- newspaper_output_tidy[ ! newspaper_output_tidy$index %in% #remove sentences with at least one mis-tagged word based on index value
                                                        mistagged_sentences_news$index, ]

#novel corpus
novel_output_tidy <- corpus2class %>%
  filter(corpus == "novel") %>%
  pivot_longer(cols = 10:11, #split text from feature
               names_to = "feature",
               values_to = "text") %>%
  unnest_tokens(text, 
                text,
                strip_punct = FALSE) %>% #unnest words from text string
  ungroup() %>%
  group_by(index, feature) %>%
  mutate(row = row_number()) %>%
  pivot_wider(names_from = feature, #create two columns, one for tags and one for text
              values_from = text) %>%
  select(-row)

mistagged_sentences_nov <- novel_output_tidy %>% #save mis-tagged sentences as a list
  filter(tag == "x" |
           is.na(tag)) %>% #filter for words/phrases where POS tagging failed ('x' tagged)
  as.list(index) #add to list object

corpus2class_clean <- corpus2class[ ! corpus2class$index %in% #remove sentences with at least one mis-tagged word based on index value
                                      mistagged_sentences_nov$index, ]

novel_output_tidy_clean <- novel_output_tidy[ ! novel_output_tidy$index %in% #remove sentences based on index value
                                                mistagged_sentences_nov$index, ]

nrow(corpus2class) - nrow(corpus2class_clean) #total number of sentences removed after filtering

remove(mistagged_sentences_news, mistagged_sentences_nov)

# CLASSIFICATION MODEL ---------------------------------------------------------

#split data into training and testing sets
`500k_newspaper` <- corpus2class_clean[sample(which(corpus2class_clean$corpus == "newspaper"),
                                              500000),] #500k random sentence sample from newspaper corpus
`500k_novel` <- corpus2class_clean[sample(which(corpus2class_clean$corpus == "novel"), 
                                          500000),] #500k random sample from novel corpus

corpus_1M <- bind_rows(`500k_novel`,
                       `500k_newspaper`) #1M sentence corpus

corpus_split <- initial_split(corpus_1M,
                              strata = corpus,
                              prop = 0.8) #80/20 training-testing split

corpus_train <- training(corpus_split) #create training data frame
corpus_test <- testing(corpus_split) #create testing data frame

corpus_folds <- vfold_cv(corpus_train,
                         v = 10) #set training set to be used for cross-validation, defaults to ten folds
corpus_folds #check

#set tuning lasso hyper-parameters
tune_spec <- logistic_reg(penalty = tune(), 
                          mixture = 1) %>%
  set_mode("classification") %>%
  set_engine("glmnet")
tune_spec

project_rec_2feat <- #define formula for classification model and data frame
  recipe(corpus ~ text + tag,
         data = corpus_train)

project_rec_2feat_ngrams <- project_rec_2feat %>% #add tokenizing steps to recipe
  step_tokenize(text:tag,
                columns = c("text", "tag"),
                token = "words") %>% #tokenize
  step_ngram(tag, 
             columns = c("tag"),
             num_tokens = 2,
             min_num_tokens = 2) %>% #min defaults to 3, changed to prevent inequality
  step_tokenfilter(text:tag,
                   columns = c("text", "tag"),
                   max_tokens = 1e3) %>% #override filter that limits the number of unique sentences
  step_tfidf(text:tag,
             columns = c("text", "tag")) 

#the following recipe can be used, whihc performs classification without n_grams
# project_rec_2feat <- project_rec_2feat %>%
#   step_tokenize(text:tag,
#                 columns = c("text", "tag"),
#                 token = "words") %>% #tokenize
#   step_tokenfilter(text:tag,
#                    columns = c("text", "tag"),
#                    max_tokens = 1e3) %>% #override filter that limits the number of unique sentences
#   step_tfidf(text:tag,
#              columns = c("text", "tag")) #%>% 

set.seed(234)

#create modelling workflow
more_vars_wf <- workflow() %>% 
  add_recipe(project_rec_2feat_ngrams) %>% 
  add_model(tune_spec)
more_vars_wf #check workflow steps: tokenize, ngram, filter, tidy

more_vars_rs <- tune_grid( #compute a set of performance metrics on re-samples
  more_vars_wf,
  corpus_folds) 

more_vars_rs %>% 
  show_best("roc_auc") #check for best ROC

chosen_auc <- more_vars_rs  %>% #select and define ROC by penalty
  select_by_one_std_err(metric = "roc_auc", -penalty)

finalize_workflow(more_vars_wf,#finalize workflow with selected ROC
                  select_best(more_vars_rs, "roc_auc")) %>% 
  fit(corpus_train) %>% 
  extract_fit_parsnip() %>% 
  tidy() %>% 
  arrange(-abs(estimate)) %>%
  mutate(term_rank = row_number()) %>% 
  filter(!str_detect(term, "tfidf"))

final_grid <- grid_regular(
  penalty(range = c(-4, 0)),
  levels = c(penalty = 20))

set.seed(2022)
tune_rs <- tune_grid( #compute a set of performance metrics on re-samples after tuning
  more_vars_wf,
  corpus_folds,
  grid = final_grid,
  metrics = metric_set(accuracy, sensitivity, specificity))

choose_acc <- tune_rs %>%
  select_by_pct_loss(metric = "accuracy", -penalty)

final_wf <- finalize_workflow(more_vars_wf, choose_acc) #finalize workflow

final_fitted <- last_fit(final_wf, corpus_split)
collect_metrics(final_fitted)

collect_predictions(final_fitted) %>% #plot classification results
  conf_mat(truth = corpus, estimate = .pred_novel) %>%
  autoplot(type = "heatmap")

classification_result <- #results to data frame
  final_fitted %>%
  extract_fit_parsnip() %>%
  tidy() %>%
  arrange(-estimate)

corpus_imp <- extract_fit_parsnip(final_fitted$.workflow[[1]]) %>% #extract model features by importance
  vi(lambda = choose_acc$penalty)

corpus_imp$Importance <- ifelse(corpus_imp$Sign == "NEG", -1*corpus_imp$Importance, corpus_imp$Importance)

corpus_imp <- corpus_imp %>%  #rewrite column variables and observations
  mutate(str = str_remove_all(Variable, "tfidf_")) %>% 
  mutate(reshape2::colsplit(str, '_', names =  c('feature_type','feature'))) %>% 
  mutate(corpus = case_when(Sign == "POS" ~ "more novel",
                            Sign == "NEG" ~ "more newspaper"))

# Select top model features
# Here, the top 25 terms are chosen, but the number of top terms can be changed 
# The number of top terms will be x-1, where x is here 26

more_news <- corpus_imp %>% #more newspaper
  filter(!between(dense_rank(Importance), 26, n() - 26))
more_nov <- corpus_imp %>% #more novel
  filter(!between(dense_rank(desc(Importance)), 26, n() -26))

top_model_terms <- bind_rows(more_news,
                             more_nov)

corpus_bind <- collect_predictions(final_fitted) %>%
  bind_cols(corpus_test %>% select(-corpus)) #join corpus to model predictions

#See mis-classified sentences, here defined as those with probability less than 20%
misclass_nov <- corpus_bind %>%
  filter(corpus == "novel", .pred_novel < 0.2) %>%
  select(text) %>%
  slice_sample(n = 1000)

misclass_news <- corpus_bind %>%
  filter(corpus == "newspaper", .pred_newspaper < 0.2) %>%
  select(text) %>%
  slice_sample(n = 1000)

# PROBABILITY ANALYSIS ----------------------------------------------------------

`500k_novel`$tag <- tolower(`500k_novel`$tag) #make all tags lowercase for comparison to model
`500k_novel`$tag <- str_squish(`500k_novel`$tag)

`500k_novel`$text <- tolower(`500k_novel`$text) #make all text lowercase for comparison to model
`500k_novel`$text <- str_squish(`500k_novel`$text)

top_features_nov <- corpus_imp %>% 
  filter(Sign == "POS") %>% 
  mutate(str = str_remove_all(Variable, "tfidf_")) %>% 
  mutate(reshape2::colsplit(str, '_', names =  c('feature_type','feature')))

top_text_nov <- top_features_nov %>% 
  filter(feature_type == "text")
top_text_nov <- as.data.frame(top_text_nov$feature)
colnames(top_text_nov)[1] <- "feature"
top_text_nov <- top_text_nov %>% 
  mutate(score_text = 1)

top_tag_nov <- top_features_nov %>% 
  filter(feature_type == "tag")
top_tag_nov <- as.data.frame(top_tag_nov$feature)
colnames(top_tag_nov)[1] <- "feature"
top_tag_nov <- top_tag_nov %>% 
  mutate(score_tag = 1)

  #NOVELS

scores_nov_text <- `500k_novel` %>% 
  rowid_to_column() %>% 
  mutate(text = strsplit(text, " ", fixed = TRUE)) %>% 
  unnest(cols = c(text, tag)) %>% 
  full_join(top_text_nov, by = c("text" = "feature")) %>% 
  group_by(index, file_name) %>%
  summarise(text = paste(text, collapse = " "),
            scores_text_nov = sum(score_text, na.rm = TRUE)) %>% # where score = number of top features in a given sentence
  ungroup()

scores_nov_tag <- `500k_novel` %>% 
  unnest_tokens(bigram, 
                tag, 
                token = "ngrams", 
                n = 2, 
                n_min = 2) 

scores_nov_tag$bigram <- gsub(' ','_',scores_nov_tag$bigram)

scores_nov_tag <- scores_nov_tag %>% 
  full_join(top_tag_nov, 
            by = c("bigram" = "feature")) %>% 
  group_by(index, file_name) %>%
  summarise(tag = paste(bigram, 
                        collapse = " "),
            scores_tag_nov = sum(score_tag, 
                                 na.rm = TRUE),
            .groups = "keep") %>% # where score = number of top features in a given sentence
  ungroup()

scores_nov <- full_join(scores_nov_text, 
                        scores_nov_tag, )

sentence_scores_nov <- `500k_novel` %>%  
  rowid_to_column() %>% 
  right_join(scores_nov, 
             by = c("index", "text", "file_name")) %>% 
  mutate(sentence_length = str_count(text, "\\S+")) %>% 
  mutate(prob_nov_text = scores_text_nov / #number of top features/
           sentence_length,
         prob_nov_tag = scores_tag_nov / (sentence_length),
         prob_nov = (prob_nov_text + prob_nov_tag)/2) %>% #create new variable for probability of being from a novel (prob_nov)
  rename(tag = tag.x,
         tag_bigram = tag.y)

  #NEWS

top_features_news <- corpus_imp %>% 
  filter(Sign == "NEG") %>% 
  mutate(str = str_remove_all(Variable, "tfidf_")) %>% 
  mutate(reshape2::colsplit(str, '_', names =  c('feature_type','feature')))

top_text_news <- top_features_news %>% 
  filter(feature_type == "text")
top_text_news <- as.data.frame(top_text_news$feature)
colnames(top_text_news)[1] <- "feature"
top_text_news <- top_text_news %>% 
  mutate(score_text = 1)

top_tag_news <- top_features_news %>% 
  filter(feature_type == "tag")
top_tag_news <- as.data.frame(top_tag_news$feature)
colnames(top_tag_news)[1] <- "feature"
top_tag_news <- top_tag_news %>% 
  mutate(score_tag = 1)

scores_news_text <- `500k_novel` %>% 
  rowid_to_column() %>% 
  mutate(text = strsplit(text, " ", fixed = TRUE)) %>% 
  unnest(cols = c(text, tag))%>% 
  full_join(top_text_news, by = c("text" = "feature")) %>% 
  group_by(index, file_name) %>%
  summarise(text = paste(text, collapse = " "),
            scores_text_news = sum(score_text, na.rm = TRUE)) %>% # where score = number of top features in a given sentence
  ungroup() %>% 
  na.omit()

scores_news_tag <- `500k_novel` %>% 
  unnest_tokens(bigram, 
                tag, 
                token = "ngrams", 
                n = 2, 
                n_min = 2) 

scores_news_tag$bigram <- gsub(' ','_',scores_news_tag$bigram)

scores_news_tag <- scores_news_tag %>% 
  full_join(top_tag_news, 
            by = c("bigram" = "feature")) %>% 
  group_by(index, file_name) %>%
  summarise(tag = paste(bigram, 
                        collapse = " "),
            scores_tag_news = sum(score_tag, 
                                  na.rm = TRUE),
            .groups = "keep") %>% # where score = number of top features in a given sentence
  ungroup() %>% 
  na.omit()

scores_news <- full_join(scores_news_text, 
                         scores_news_tag, )

sentence_scores_news <- `500k_novel` %>%  
  rowid_to_column() %>% 
  right_join(scores_news, 
             by = c("index", "text", "file_name")) %>% 
  mutate(sentence_length = str_count(text, "\\S+")) %>% 
  mutate(prob_news_text = scores_text_news / #number of top features/
           sentence_length,
         prob_news_tag = scores_tag_news / sentence_length,
         prob_news = (prob_news_text + prob_news_tag)/2) %>%  #create new variable for probability of being from a newspaper (prob_nov)
  rename(tag = tag.x,
         tag_bigram = tag.y)

full_prob <- 
  full_join(sentence_scores_nov,
            sentence_scores_news,
            by = c("text","corpus", "file_name", "index", "pub_year", "rowid",
                   "tag","tags", "tag_bigram", "sentence_length",
                   "relative_sentence_index", "author","gender", "source", "news_novel")) %>%
  mutate(tot_hits = scores_tag_news + scores_text_news + scores_tag_nov + scores_text_nov,
         prob_news2 = (scores_text_news + scores_tag_news) / tot_hits,
         prob_nov2 = (scores_text_nov + scores_tag_nov)  / tot_hits) %>% 
  rename(title = file_name) %>% 
  mutate(title = str_replace_all(title, "_", " ")) %>% 
  mutate(title = str_replace_all(title, ".txt", "")) 

full_prob$pub_year <- as.numeric(full_prob$pub_year)

full_prob_meta <- 
  full_join(full_prob,
            titles,
            by = c("title", "pub_year", "news_novel"))

news_titles <- full_prob_meta %>% 
  group_by(title, corpus, author, news_novel, pub_year) %>% 
  na.omit(prob_news2) %>% 
  summarise(mean_news = mean(prob_news2))

#add sentence lengths
sentence_lengths <- corpus_output %>% 
  filter(corpus == 1) %>% 
  mutate(sentence_length = str_count(text, "\\S+")) %>% 
  rename(title = file_name) %>% 
  mutate(title = str_replace_all(title, "_", " ")) %>% 
  mutate(title = str_replace_all(title, ".txt", "")) %>% 
  group_by(title) %>%
  summarise(mean_sl = mean(sentence_length))

news_titles <- 
  full_join(news_titles,
            sentence_lengths,
            by = c("title"))

nov_titles <- full_prob_meta %>% 
  group_by(title, pub_year, corpus, author, news_novel) %>%
  na.omit(prob_nov2) %>% 
  summarise(mean_nov = mean(prob_nov2))

# STATS ---------------------------------------------------------------------

news_titles$date <- as.numeric(news_titles$date)

hist(news_titles$date)
ggplot(news_titles, 
       aes(x = as.numeric(date), 
           y = mean_news)) + 
  geom_point(aes(colour = news_novel)) + 
  geom_smooth(method = "lm")

lm_news <- lm(mean_news ~ as.numeric(date) + news_novel,
              news_titles)
summary(lm_news)