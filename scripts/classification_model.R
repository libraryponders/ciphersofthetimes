# PACKAGES ####

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

# DATA INPUT ####
setwd("~/Desktop/R") #set working directory
#input data
corpus_output <- read_csv("Data Input/libponders_meta.csv")

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

#remove any double spaces between in text and tags 
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

# FILTERING ####
titles <- corpus2class %>%
  filter(corpus == "novel") %>%
  group_by(pub_year, news_novel) %>%
  mutate(title = str_replace_all(file_name, "_", " ")) %>% 
  mutate(title = str_replace_all(title, ".txt", "")) %>% 
  summarise(title = unique(title))
titles$pub_year <- as.numeric(titles$pub_year)

#cast as tidy, tokenized data frame
#newspaper corpus
newspaper_output_tidy <- corpus2class %>%
  filter(corpus == "newspaper") %>%
  pivot_longer(cols = 10:11,
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
nrow(newspaper_output_tidy) #count the number of words in the newspaper corpus

mistagged_sentences_news <- newspaper_output_tidy %>% #save mistagged sentences as a list
  filter(tag == "x" |
           is.na(tag)) %>% #filter for words/phrases where POS tagging failed ('x' tagged or NA)
  as.list(index) #add to list object

#remove sentences with at least one mistagged word
corpus2class_clean <- corpus2class[ ! corpus2class$index %in% #remove sentences based on index value
                                      mistagged_sentences_news$index, ]

mistagged_sentences_news %>% #count number of tags lost from newspaper corpus
  as.data.frame() %>%
  summarize(count(unique(index)))

mistagged_sentences_news %>% #count number of sentences lost from newspaper corpus
  as.data.frame() %>%
  n_distinct(index)

newspaper_output_tidy_clean <- newspaper_output_tidy[ ! newspaper_output_tidy$index %in% #remove sentences based on index value
                                                        mistagged_sentences_news$index, ]

pos_stats_news <- newspaper_output_tidy_clean %>% #summarize 
  group_by(tag, year) %>%
  summarise(count=n())

tot_tags_news <- pos_stats_news %>%
  group_by(year) %>%
  summarise(year_tot = sum(count))

pos_stats_news <- full_join(tot_tags_news,
                            pos_stats_news,
                            by = c("year"))

pos_stats_news <- pos_stats_news %>%
  mutate(prop = ((count/year_tot) * 100))

write.csv(pos_stats_news,"/Users/digitalhumanities/Documents/R/App-1/data/pos_stats_news.csv", row.names = FALSE) #write output to App-1

#novel corpus
novel_output_tidy <- corpus2class %>%
  filter(corpus == "novel") %>%
  pivot_longer(cols = 10:11,
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

nrow(novel_output_tidy) #count the number of words in the novel corpus

mistagged_sentences_nov <- novel_output_tidy %>% #save mistagged sentences as a list
  filter(tag == "x" |
           is.na(tag)) %>% #filter for words/phrases where POS tagging failed ('x' tagged)
  as.list(index) #add to list object

#remove sentences with at least one mistagged word
corpus2class_clean <- corpus2class[ ! corpus2class$index %in% #remove sentences based on index value
                                      mistagged_sentences_nov$index, ]

corpus2class_clean %>%
  filter(tag == "x" |
           is.na(tag))  #check that sentences have been removed

mistagged_sentences_nov %>% #count number of sentences lost from newspaper corpus
  as.data.frame() %>%
  n_distinct(index)

novel_output_tidy_clean <- novel_output_tidy[ ! novel_output_tidy$index %in% #remove sentences based on index value
                                                mistagged_sentences_nov$index, ]

#novel_output_tidy_clean <- novel_output_tidy %>%
#  filter(!tag == "x") %>%
#  drop_na()

pos_stats_nov <- novel_output_tidy_clean %>%
  group_by(tag) %>%
  summarise(count=n())

tot_tags_nov <- pos_stats_nov %>%
  summarise(year_tot = sum(count))
tot_tags_nov <- as.numeric(tot_tags_nov)

pos_stats_nov <- pos_stats_nov %>%
  mutate(prop = ((count/tot_tags_nov) * 100))

write.csv(pos_stats_nov,"/Users/digitalhumanities/Documents/R/App-1/data/pos_stats_nov.csv", row.names = FALSE)

pos_stats_nov_all <- novel_output_tidy_clean %>%
  group_by(tag,file_name, pub_year, author) %>%
  summarise(count=n())

tot_tags_nov_all <- pos_stats_nov_all %>%
  group_by(file_name) %>%
  summarise(nov_tot = sum(count))

pos_stats_nov_all <- full_join(tot_tags_nov_all,
                               pos_stats_nov_all,
                               by = c("file_name"))

pos_stats_nov_all <- pos_stats_nov_all %>%
  mutate(prop = ((count/nov_tot) * 100))

pos_stats_nov_all <- pos_stats_nov_all %>% 
  mutate(title = str_replace_all(file_name, "_", " ")) %>% 
  mutate(title = str_replace_all(title, ".txt", ""))

write.csv(pos_stats_nov_all,"/Users/digitalhumanities/Documents/R/App-1/data/pos_stats_nov_all.csv", row.names = FALSE)

#check for comparability between corpora
corpus2class_clean %>%
  group_by(corpus) %>%
  count()

nrow(corpus2class) - nrow(corpus2class_clean) #total number of sentences removed after filtering

remove(mistagged_sentences_news, mistagged_sentences_nov,
       tot_tags_news, tot_tags_nov_all,
       pos_stats_news, pos_stats_nov, pos_stats_nov_all)

# CLASSIFICATION MODEL####

#split data into training and testing sets
`500k_newspaper` <- corpus2class_clean[sample(which(corpus2class_clean$corpus == "newspaper"),500000),] #500k random sentence sample from newspaper corpus
`500k_novel` <- corpus2class_clean[sample(which(corpus2class_clean$corpus == "novel"), 500000),] #500k random sample from novel corpus

corpus_1M <- bind_rows(`500k_novel`,
                       `500k_newspaper`)

corpus_split <- initial_split(corpus_1M,
                              strata = corpus,
                              prop = 0.8) #80/20 training-testing split

corpus_train <- training(corpus_split) #create training data frame
dim(corpus_train)
corpus_test <- testing(corpus_split) #create testing data frame
dim(corpus_test)

corpus_folds <- vfold_cv(corpus_train,
                         v = 10) #set training set to be used for cross-validation, defaults to ten folds
corpus_folds #check

#set tuning lasso hyperparameters
tune_spec <- logistic_reg(penalty = tune(), 
                          mixture = 1) %>%
  set_mode("classification") %>%
  set_engine("glmnet")
tune_spec

project_rec_2feat <- #define formula for classification model and data frame
  recipe(corpus ~ text + tag,
         data = corpus_train)

project_rec_2feat_ngrams <- project_rec_2feat %>%
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

project_rec_2feat <- project_rec_2feat %>%
  step_tokenize(text:tag,
                columns = c("text", "tag"),
                token = "words") %>% #tokenize
  step_tokenfilter(text:tag,
                   columns = c("text", "tag"),
                   max_tokens = 1e3) %>% #override filter that limits the number of unique sentences
  step_tfidf(text:tag,
             columns = c("text", "tag")) #%>% 

set.seed(234)

#create modelling workflow
more_vars_wf <- workflow() %>% 
  add_recipe(project_rec_2feat_ngrams) %>% 
  add_model(tune_spec)
more_vars_wf #check workflow steps: tokenize, ngram, filter, tidy

more_vars_rs <- tune_grid(
  more_vars_wf,
  corpus_folds)

more_vars_rs %>% 
  show_best("roc_auc")

chosen_auc <- more_vars_rs  %>%
  select_by_one_std_err(metric = "roc_auc", -penalty)
chosen_auc

finalize_workflow(more_vars_wf,
                  select_best(more_vars_rs, "roc_auc")) %>% 
  fit(corpus_train) %>% 
  extract_fit_parsnip() %>% 
  tidy() %>% 
  arrange(-abs(estimate)) %>%
  mutate(term_rank = row_number()) %>% 
  filter(!str_detect(term, "tfidf"))

final_grid <- grid_regular(
  penalty(range = c(-4, 0)),
  #max_tokens(range = c(1e3, 3e3)),
  levels = c(penalty = 20 #max_tokens = 3
  )
)
final_grid

set.seed(2022)
tune_rs <- tune_grid(
  more_vars_wf,
  corpus_folds,
  grid = final_grid,
  metrics = metric_set(accuracy, sensitivity, specificity))

autoplot(tune_rs) +
  labs(
    color = "Number of tokens",
    title = "Model performance across regularization penalties and tokens",
    subtitle = paste("We can choose a simpler model with higher regularization")
  )

choose_acc <- tune_rs %>%
  select_by_pct_loss(metric = "accuracy", -penalty)
choose_acc

final_wf <- finalize_workflow(more_vars_wf, choose_acc)
final_wf

final_fitted <- last_fit(final_wf, corpus_split)
collect_metrics(final_fitted)

collect_predictions(final_fitted) %>%
  conf_mat(truth = corpus, estimate = .pred_novel) %>%
  autoplot(type = "heatmap")

classification_result <- 
  final_fitted %>%
  extract_fit_parsnip() %>%
  tidy() %>%
  arrange(-estimate)

corpus_imp <- extract_fit_parsnip(final_fitted$.workflow[[1]]) %>%
  vi(lambda = choose_acc$penalty)

corpus_imp$Importance <- ifelse(corpus_imp$Sign == "NEG", -1*corpus_imp$Importance, corpus_imp$Importance)

# corpus_imp %>%
#   mutate(
#     Sign = case_when(Sign == "POS" ~ "More novel",
#                      Sign == "NEG" ~ "More newspaper"),
#     #Importance = abs(Importance),
#     Variable = str_remove_all(Variable, "tfidf_"),
#   ) %>%
#   group_by(Sign) %>%
#   top_n(50, Importance) %>%
#   ungroup %>%
#   ggplot(aes(x = Importance,
#              y = fct_reorder(Variable, Importance),
#              fill = Sign)) +
#   geom_col(show.legend = FALSE) +
#   scale_x_continuous(expand = c(0, 0)) +
#   facet_wrap(~Sign, scales = "free") +
#   labs(
#     y = NULL,
#     title = "Variable importance for predicting the corpus of a sentence",
#     subtitle = paste0("These features are the most important in predicting",
#                       "whether a sentence is from a newspaper or a novel")
#   )

corpus_imp <- corpus_imp %>% 
  mutate(str = str_remove_all(Variable, "tfidf_")) %>% 
  mutate(reshape2::colsplit(str, '_', names =  c('feature_type','feature'))) %>% 
  mutate(corpus = case_when(Sign == "POS" ~ "more novel",
                            Sign == "NEG" ~ "more newspaper"))

more_news <- corpus_imp %>%
  filter(!between(dense_rank(Importance), 26, n() - 26))
more_nov <- corpus_imp %>%
  filter(!between(dense_rank(desc(Importance)), 26, n() -26))

top_model_terms <- bind_rows(more_news,
                             more_nov)

write.csv(top_model_terms,"/Users/digitalhumanities/Documents/R/App-1/data/top_model_terms.csv", row.names = FALSE)

corpus_bind <- collect_predictions(final_fitted) %>%
  bind_cols(corpus_test %>% select(-corpus))

misclass_nov <- corpus_bind %>%
  filter(corpus == "novel", .pred_novel < 0.2) %>%
  select(text) %>%
  slice_sample(n = 1000)

misclass_news <- corpus_bind %>%
  filter(corpus == "newspaper", .pred_newspaper < 0.2) %>%
  select(text) %>%
  slice_sample(n = 1000)

#PROBABILITY ANALYSIS ####

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
  ungroup() #%>% 
#na.omit()

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

write.csv(full_prob_meta,"/Users/digitalhumanities/Documents/R/App-1/data/full_prob_meta.csv", row.names = FALSE)

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

write.csv(news_titles,"/Users/digitalhumanities/Documents/R/App-1/data/news_titles.csv", row.names = FALSE)

nov_titles <- full_prob_meta %>% 
  group_by(title, pub_year, corpus, author, news_novel) %>%
  na.omit(prob_nov2) %>% 
  summarise(mean_nov = mean(prob_nov2))

write.csv(nov_titles,"/Users/digitalhumanities/Documents/R/App-1/data/nov_titles.csv", row.names = FALSE)

#### STATS

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