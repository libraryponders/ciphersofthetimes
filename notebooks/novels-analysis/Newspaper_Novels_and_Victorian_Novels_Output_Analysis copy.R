#packages 
library(tidyverse)
library(ggrepel)
library(patchwork)

#load corpora results
newsnovels <- #load newspaper novel corpus results
  read_csv("ownCloud/Riddle2020/Agony Column Project/Data Analysis/2_Data Automation/2022_03_13_Organized_DH_Project/spreadsheets/df_nnovels_meta.csv")

newsnovels <- #add column for corpus
  newsnovels %>% 
  mutate(corpus = "newspaper")

vicnovels <- #load Victorian novel corpus results
  read_csv("ownCloud/Riddle2020/Agony Column Project/Data Analysis/2_Data Automation/2022_03_13_Organized_DH_Project/spreadsheets/df_txtlab_meta.csv")

vicnovels <- #add column for corpus
  vicnovels %>% 
  mutate(corpus = "victorian")

all_novels <- bind_rows(newsnovels, 
                        vicnovels) #join data frames

all_novels_head <- head(all_novels)

all_novels$year = all_novels$book_year
all_novels$book_year <- as.Date(as.character(all_novels$book_year), 
                                format = "%Y") #change `book_year` to an object of class date

all_novels <- #add column specifying decade title was published 
all_novels %>%
  mutate(decade = case_when(book_year < "1799-12-31" ~ "Pre-1800",
                            book_year > "1800-01-01" & 
                              book_year < "1809-12-31" ~ "1800s",
                            book_year > "1810-01-01" & 
                              book_year < "1819-12-31" ~ "1810s",
                            book_year > "1820-01-01" & 
                              book_year < "1829-12-31" ~ "1820s",
                            book_year > "1830-01-01" & 
                              book_year < "1839-12-31" ~ "1830s",
                            book_year > "1840-01-01" & 
                              book_year < "1849-12-31" ~ "1840s",
                            book_year > "1850-01-01" & 
                              book_year < "1859-12-31" ~ "1850s",
                            book_year > "1860-01-01" & 
                              book_year < "1869-12-31" ~ "1860s",
                            book_year > "1870-01-01" & 
                              book_year < "1879-12-31" ~ "1870s",
                            book_year > "1880-01-01" & 
                              book_year < "1889-12-31" ~ "1880s",
                            book_year > "1890-01-01" & 
                              book_year < "1899-12-31" ~ "1890s",
                            book_year > "1900-01-01" ~ "Post-1900"))
         

all_novels$decade <- factor(all_novels$decade, #order decades chronologically
                            levels = c("Pre-1800", "1800s","1810s", 
                                       "1820s", "1830s", "1840s", 
                                       "1850s", "1860s", "1870s", 
                                       "1880s", "1890s", "Post-1900"))
                   
titles_by_decade <- #count titles by decade
  all_novels %>% 
  group_by(decade, corpus) %>% 
  count()

ggplot(titles_by_decade,
       aes(x = decade,
           y = `n`)) +
  geom_line(aes(colour = corpus, 
                group = corpus)) +
  geom_point(aes(colour = corpus, 
                 group = corpus)) + 
  geom_label_repel(data=titles_by_decade,
                   aes(x = decade,
                       y = `n`,
                       label = `n`)) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) + 
  theme_bw() +
  labs(title = "Titles by Decade", 
       x = "Decade",
       y = "Number of Titles",
       colour = "Corpus")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "line_titles_by_decade.png",
       height = 30,
       width = 40,
       units = c("cm"))

titles_by_gender <- #count titles by gender
  all_novels %>% 
  group_by(gender, corpus) %>% 
  count()

titles_by_voice <- #count titles by voice
  all_novels %>% 
  group_by(person, corpus) %>% 
  count()

#Distributions ####

hist(all_novels$words_count_stopless) #not normally distributed. 

ggplot(data = all_novels,
       aes(x = words_count_stopless)) + 
  geom_histogram(bins = 10) + 
  theme_bw() + 
  labs(x = "Word Count (Stopless)",
       y = "Count",
       title = "Word Count Histogram")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_all_novel_stopless.png",
       height = 20,
       width = 20,
       units = c("cm"))

hist(all_novels$words_count_stopped) #not normally distributed. 
hist(all_novels$year) #not normally distributed. 

all_novels <- 
  all_novels %>% 
  mutate(log_stopless = log(words_count_stopless))

hist(all_novels$log_stopless) #now normally distributed.

ggplot(data = all_novels,
       aes(x = log_stopless)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "log Word Count (Stopless)",
       y = "Count",
       title = "log Word Count Histogram")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_all_novel_stopless_log.png",
       height = 20,
       width = 20,
       units = c("cm"))

plot(density(all_novels$log_stopless),
     main="Density Plot: Stopless Words", 
     ylab="Frequency", 
     sub=paste("Skewness:", 
               round(e1071::skewness(all_novels$log_stopless), 
                     2)))
cor(all_novels$log_stopless, all_novels$year) #no correlation between year and number of words in both corpora 

ggplot(data = all_novels,
       aes(x = book_year,
           y = log_stopless)) + 
  geom_point() + 
  theme_bw() + 
  labs(x = "Year",
       y = "log Word Count",
       title = "Word Count x Time")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "scatter_all_novel_stopless_log_time.png",
       height = 20,
       width = 30,
       units = c("cm"))

#Word Counts ####

#plot all novels
ggplot(data = all_novels,
       aes(x = book_year,
           y = log_stopless)) + 
  geom_point(aes(colour = corpus)) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) + 
  theme_bw() + 
  labs(x = "Year",
       y = "log Word Count",
       title = "Word Count x Time",
       colour = "Corpus")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "scatter_all_novel_stopless_log_time_by_corpora.png",
       height = 20,
       width = 30,
       units = c("cm"))

#Novels of Each Corpora x Time

newsnovels <- 
  newsnovels %>% 
  mutate(log_stopless = log(words_count_stopless))

vicnovels <- 
  vicnovels %>% 
  mutate(log_stopless = log(words_count_stopless))

#Newspaper Novels 

hist(newsnovels$words_count_stopless) #not normally distributed. 

ggplot(data = newsnovels,
       aes(x = words_count_stopless)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "Word Count (Stopless)",
       y = "Count",
       title = "Word Count Histogram (Newspaper Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_news_novels_stopless.png",
       height = 20,
       width = 20,
       units = c("cm"))

hist(newsnovels$log_stopless) #now normally distributed.

ggplot(data = newsnovels,
       aes(x = log_stopless)) + 
  geom_histogram(bins = 5) + 
  theme_bw() + 
  labs(x = "log Word Count (Stopless)",
       y = "Count",
       title = "log Word Count Histogram (Newspaper Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_news_novels_stopless_log.png",
       height = 20,
       width = 20,
       units = c("cm"))

plot(density(newsnovels$log_stopless),
     main="Density Plot: Stopless Words", 
     ylab="Frequency", 
     sub=paste("Skewness:", 
               round(e1071::skewness(newsnovels$log_stopless), 
                     2)))

cor(newsnovels$log_stopless, newsnovels$book_year) 
  
#Victorian Novels
hist(vicnovels$words_count_stopless) #not normally distributed. 

ggplot(data = vicnovels,
       aes(x = words_count_stopless)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "Word Count (Stopless)",
       y = "Count",
       title = "Word Count Histogram (Victorian Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_vic_novels_stopless.png",
       height = 20,
       width = 20,
       units = c("cm"))

hist(vicnovels$log_stopless) #now normally distributed.

ggplot(data = vicnovels,
       aes(x = log_stopless)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "log Word Count (Stopless)",
       y = "Count",
       title = "log Word Count Histogram (Victorian Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_vic_novels_stopless_log.png",
       height = 20,
       width = 20,
       units = c("cm"))

plot(density(vicnovels$log_stopless),
     main="Density Plot: Stopless Words", 
     ylab="Frequency", 
     sub=paste("Skewness:", 
               round(e1071::skewness(vicnovels$log_stopless), 
                     2)))

cor(vicnovels$log_stopless, vicnovels$book_year) 

#GLMs
words_news <- glm(log_stopless ~ book_year,
                  data = subset(all_novels, 
                                corpus == "newspaper"))
words_vic <- glm(log_stopless ~ book_year,
                 data = subset(all_novels, 
                               corpus == "victorian"))

summary.glm(words_news)
summary.glm(words_vic)

#plot 
news_words_time <-
ggplot(data = subset(all_novels,
                     corpus == "newspaper"),
       aes(x = book_year,
           y = log_stopless)) + 
  geom_point(colour = "red") + 
  geom_smooth(method = "lm", 
              se = T, 
              colour = "black", 
              linetype = "dashed", 
              size = 0.5) + 
  theme_bw() + 
  labs(title = "Word Count (Newspaper Novels) x Year", 
       x = "Publication Year",
       y = "Log Word Count (Stopless)")

vic_words_time <-
ggplot(data = subset(all_novels,
                     corpus == "victorian"),
       aes(x = book_year,
           y = log_stopless)) + 
  geom_point(colour = "blue") + 
  geom_smooth(method = "lm", 
              se = T, 
              colour = "black", 
              linetype = "dashed", 
              size = 0.5) + 
  theme_bw() + 
  labs(title = "Word Count (Victorian Novels) x Year", 
       x = "Publication Year",
       y = "Log Word Count (Stopless)")

ggpubr::ggarrange(news_words_time,
                  vic_words_time,
                  ncol = 1)

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "glm_scatter_all_novels_stopless_log_time.png",
       height = 20,
       width = 20,
       units = c("cm"))

#Number of Sentences ####

hist(all_novels$sentences_count) #not normally distributed. 

ggplot(data = all_novels,
       aes(x = sentences_count)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "Sentence Count",
       y = "Frequency",
       title = "Sentence Count Histogram (All Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_all_novels_sentence_count.png",
       height = 20,
       width = 20,
       units = c("cm"))

all_novels <- 
  all_novels %>% 
  mutate(log_sentence = log(sentences_count))

hist(all_novels$log_sentence) #now more normally distributed.
plot(density(all_novels$log_sentence),
     main="Density Plot: Sentence Count", 
     ylab="Frequency", 
     sub=paste("Skewness:", 
               round(e1071::skewness(all_novels$log_sentence), 
                     2)))

ggplot(data = all_novels,
       aes(x = log_sentence)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "log Sentence Count",
       y = "Frequency",
       title = "log Sentence Count Histogram (All Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_all_novels_sentence_count_log.png",
       height = 20,
       width = 20,
       units = c("cm"))

cor(all_novels$log_sentence, 
    all_novels$year) 

ggplot(data = all_novels,
       aes(x = book_year,
           y = log_sentence)) +
  geom_point() +
  theme_bw() + 
  labs(x = "Year",
       y = "log Sentence Count",
       title = "Sentence Count x Time")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "scatter_all_novels_sentence_count_log.png",
       height = 10,
       width = 30,
       units = c("cm"))

#Novels of Each Corpora x Time

newsnovels <- 
  newsnovels %>% 
  mutate(log_sentence = log(sentences_count))

vicnovels <- 
  vicnovels %>% 
  mutate(log_sentence = log(sentences_count))

#Newspaper Novels 

hist(newsnovels$sentences_count) #not normally distributed. 

ggplot(data = newsnovels,
       aes(x = sentences_count)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "Sentence Count",
       y = "Frequency",
       title = "Sentence Count Histogram (Newspaper Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_news_novels_sentence_count.png",
       height = 20,
       width = 20,
       units = c("cm"))

hist(newsnovels$log_sentence) #now normally distributed.

ggplot(data = newsnovels,
       aes(x = log_sentence)) + 
  geom_histogram(bins = 5) + 
  theme_bw() + 
  labs(x = "log Sentence Count",
       y = "Frequency",
       title = "log Sentence Count Histogram (Newspaper Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_news_novels_sentence_count_log.png",
       height = 20,
       width = 20,
       units = c("cm"))

plot(density(newsnovels$log_sentence),
     main="Density Plot: Sentence Count", 
     ylab="Frequency", 
     sub=paste("Skewness:", 
               round(e1071::skewness(newsnovels$log_stopless), 
                     2)))

cor(newsnovels$log_sentence, newsnovels$book_year) 

#Victorian Novels
hist(vicnovels$sentences_count) #not normally distributed. 

ggplot(data = vicnovels,
       aes(x = sentences_count)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "Sentence Count",
       y = "Frequency",
       title = "Sentence Count Histogram (Victorian Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_vic_novels_sentence_count.png",
       height = 20,
       width = 20,
       units = c("cm"))

hist(vicnovels$log_sentence) #now more normally distributed.

ggplot(data = vicnovels,
       aes(x = log_sentence)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "log Sentence Count",
       y = "Frequency",
       title = "log Sentence Count Histogram (Victorian Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_vic_novels_sentence_count_log.png",
       height = 20,
       width = 20,
       units = c("cm"))

plot(density(vicnovels$log_sentence),
     main="Density Plot: Sentence Count", 
     ylab="Frequency", 
     sub=paste("Skewness:", 
               round(e1071::skewness(vicnovels$log_stopless), 
                     2)))

cor(vicnovels$log_sentence, vicnovels$book_year) 

#GLMs
sentences_news <- glm(log_sentence ~ book_year,
                      data = subset(all_novels, 
                                    corpus == "newspaper"))
sentences_vic <- glm(log_sentence ~ book_year,
                     data = subset(all_novels, 
                                   corpus == "victorian"))

summary.glm(sentences_news)
summary.glm(sentences_vic)

#plot 
news_sentence_time <-
  ggplot(data = subset(all_novels,
                       corpus == "newspaper"),
         aes(x = book_year,
             y = log_sentence)) + 
  geom_point(colour = "red") + 
  geom_smooth(method = "lm", 
              se = T, 
              colour = "black", 
              linetype = "dashed", 
              size = 0.5) + 
  theme_bw() + 
  labs(title = "Sentence Count (Newspaper Novels) x Year", 
       x = "Publication Year",
       y = "log Sentence Count")

vic_sentence_time <-
  ggplot(data = subset(all_novels,
                       corpus == "victorian"),
         aes(x = book_year,
             y = log_sentence)) + 
  geom_point(colour = "blue") + 
  geom_smooth(method = "lm", 
              se = T, 
              colour = "black", 
              linetype = "dashed", 
              size = 0.5) + 
  theme_bw() + 
  labs(title = "Sentence Count (Victorian Novels) x Year", 
       x = "Publication Year",
       y = "Log Sentence Count")

ggpubr::ggarrange(news_sentence_time,
                  vic_sentence_time,
                  ncol = 1)

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "glm_scatter_all_novels_sentence_count_log_time.png",
       height = 20,
       width = 20,
       units = c("cm"))

#Average Length of Sentences ####
hist(all_novels$average_words_per_sentence) #not normally distributed. 

ggplot(data = all_novels,
       aes(x = average_words_per_sentence)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "Average Words/Sentence",
       y = "Frequency",
       title = "Average Words/Sentence Histogram (All Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_all_novels_average_words_sentence.png",
       height = 20,
       width = 20,
       units = c("cm"))

all_novels <- 
  all_novels %>% 
  mutate(log_average_words = log(average_words_per_sentence))

hist(all_novels$log_average_words) #now normally distributed.

ggplot(data = all_novels,
       aes(x = log_average_words)) + 
  geom_histogram(bins = 7) + 
  theme_bw() + 
  labs(x = "log Average Words/Sentence",
       y = "Frequency",
       title = "log Average Words/Sentence Histogram (All Novels)")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "hist_all_novels_average_words_sentence_Log.png",
       height = 20,
       width = 20,
       units = c("cm"))

plot(density(all_novels$log_average_words),
     main="Density Plot: Average Words per Sentence", 
     ylab="Frequency", 
     sub=paste("Skewness:", 
               round(e1071::skewness(all_novels$log_average_words), 
                     2)))

cor(all_novels$log_average_words, all_novels$year) 

words_avg <- glm(log_average_words ~ book_year,
                 data = all_novels)
words_avg_news <- glm(log_average_words ~ book_year,
                      data = subset(all_novels, 
                                    corpus == "newspaper"))
words_avg_vic <- glm(log_average_words ~ book_year,
                     data = subset(all_novels, 
                                   corpus == "victorian"))

summary.glm(words_avg)
summary.glm(words_avg_news)
summary.glm(words_avg_vic)

#now plot  
ggplot(data = all_novels,
       aes(x = book_year,
           y = log_average_words)) + 
  geom_point(data = all_novels, 
             aes(x = book_year,
                 y = log_average_words), 
             colour = "black",
             alpha = 0.5) + 
  geom_smooth(data = all_novels,
            aes(x = book_year,
                y = log_average_words), 
            colour = "black",
            linetype = "dashed",
            size = 0.5,
            method = "lm",
            se = F) + 
  theme_bw() +
  labs(title = "Average Words per Sentence x Year",
       x = "Year",
       y = "log Average Words per Sentence")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "scatter_all_novels_average_words_sentence_log_glm.png",
       height = 10,
       width = 20,
       units = c("cm"))

ggplot(data = all_novels,
       aes(x = book_year,
           y = log_average_words)) + 
  geom_point(data = subset(all_novels, 
                           corpus == "victorian"),
             aes(x = book_year,
                 y = log_average_words), 
             colour = "blue",
             alpha = 0.5) + 
  geom_point(data = subset(all_novels, 
                           corpus == "newspaper"),
             aes(x = book_year,
                 y = log_average_words), 
             colour = "red", 
             alpha = 0.5) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "newspaper"),
              aes(x = book_year,
                  y = log_average_words), 
              colour = "red",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "victorian"),
              aes(x = book_year,
                  y = log_average_words), 
              colour = "blue",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  theme_bw() + 
  labs(title = "Average Words per Sentence x Year",
       x = "Year",
       y = "log Average Words per Sentence")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "scatter_all_novels_average_words_sentence_log_glm_bycorpus.png",
       height = 10,
       width = 20,
       units = c("cm"))

#Stats
all_novels %>% 
  group_by(corpus) %>% 
  summarise(mean(average_words_per_sentence))

with(all_novels, 
     shapiro.test(log_average_words[corpus == "victorian"])) #p = <0.001
with(all_novels, 
     shapiro.test(log_average_words[corpus == "newspaper"])) #p = 0.02

res.ftest <- var.test(log_average_words ~ corpus, 
                      data = all_novels)
res.ftest

#t-test (cannot be preformed, as data is not equally distributed nor do the two groups have the same variance)
t.test(log_average_words ~ corpus, 
       data = all_novels, 
       var.equal = T)

#wilcox test for non parametric two-samples.
wilcox.test(log_average_words ~ corpus, 
            data = all_novels,
            exact = FALSE)

#Sentence Counts x Word Counts x Average Sentence Length ####

#Sentence Count x Word Count
sentences_x_stopless <- 
  glm(log_sentence ~ log_stopless,
      data = all_novels)

summary.glm(sentences_x_stopless)

sent_x_stop <-
ggplot(data = all_novels,
       aes(x = log_stopless,
           y = log_sentence)) + 
  geom_point(aes(colour = corpus),
             alpha = 0.5) + 
  geom_smooth(method = "lm", 
              se = F, 
              colour = "black", 
              linetype = "dashed", 
              size = 0.5) + 
  scale_colour_manual(values = c("red","blue"),
                        labels = c("Newspaper", "Victorian")) + 
  #geom_label_repel(data = subset(all_novels,
  #                               log_sentence > 10 &
  #                                 corpus == "newspaper"),
  #                 aes(label = book_title)) +
  theme_bw() +
  labs(title = "Sentence Count x Word Count", 
       x = "log Word Count",
       y = "log Sentence Count",
       colour = "Corpus")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "scatter_all_novels_sentence_words_log_glm_bycorpus.png",
       height = 10,
       width = 20,
       units = c("cm"))

#Word Counts x Sentence Length
average_x_stopless <- 
  glm(log_average_words ~ log_stopless,
      data = all_novels)
summary.glm(average_x_stopless)

stop_x_average <-
ggplot(data = all_novels,
       aes(x = log_stopless,
           y = log_average_words)) + 
  geom_point(aes(colour = corpus),
             alpha = 0.5) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) + 
  theme_bw() +
  labs(title = "Word Counts x Average Sentence Length", 
       x = "log Word Count",
       y = "log Sentence Length",
       colour = "Corpus")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "scatter_all_novels_sentence_length_words_log_glm_bycorpus.png",
       height = 10,
       width = 20,
       units = c("cm"))

#Average Sentence Length x Sentence Count
average_x_sentence <- 
  glm(log_average_words ~ log_sentence,
      data = all_novels)
summary.glm(average_x_sentence)

#news
average_x_sentence_news <- 
  glm(log_average_words ~ log_sentence,
      data = subset(all_novels,
                    corpus =="newspaper"))
summary.glm(average_x_sentence_news)

#victorian
average_x_sentence_vic <- 
  glm(log_average_words ~ log_sentence,
      data = subset(all_novels,
                    corpus =="victorian"))
summary.glm(average_x_sentence_vic)

#plot
sent_x_average <-
ggplot(data = all_novels,
       aes(x = log_sentence,
           y = log_average_words)) + 
  geom_point(data = subset(all_novels, 
                           corpus == "victorian"),
             colour = "blue",
             alpha = 0.5) + 
  geom_point(data = subset(all_novels, 
                           corpus == "newspaper"),
             colour = "red", 
             alpha = 0.5) + 
  geom_smooth(colour = "black",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  #geom_smooth(data = subset(all_novels, 
  #                          corpus == "newspaper"),
  #            colour = "red",
  #            linetype = "dashed",
  #            size = 0.5,
  #            method = "lm",
  #            se = F) + 
  #geom_smooth(data = subset(all_novels, 
  #                          corpus == "victorian"),
  #            colour = "blue",
  #            linetype = "dashed",
  #            size = 0.5,
  #            method = "lm",
  #            se = F) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) + 
  theme_bw() +
  labs(title = "Sentence Count x Average Sentence Length", 
       x = "log Sentence Count",
       y = "log Sentence Length",
       colour = "Corpus")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "scatter_all_novels_sentence_length_words_log_glm_bycorpus.png",
       height = 10,
       width = 20,
       units = c("cm"))

#all plots 

ggpubr::ggarrange(sent_x_stop,
                  sent_x_average,
                  stop_x_average,
                  ncol = 1,
                  common.legend = T,
                  legend = "bottom")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "scatter_all_novels_sent_stop_average_log_glm_bycorpus.png",
       height = 30,
       width = 20,
       units = c("cm"))

#Average Number of Words/Sentence vs... ####

newsnovels <- 
  newsnovels %>% 
  mutate(log_average_words = log(average_words_per_sentence))

vicnovels <- 
  vicnovels %>% 
  mutate(log_average_words = log(average_words_per_sentence))

#newspaper 15.8
#victorian 17.9

#On average, Victorian novels writ-large have a greater number of words per sentence
#We would expect, then, that 

#Verbs 
all_novels %>% 
  group_by(corpus) %>% 
  summarise(mean(`%POS_VERB`))

with(all_novels, 
     shapiro.test(`%POS_VERB`[corpus == "victorian"])) #p = 0.30
with(all_novels, 
     shapiro.test(`%POS_VERB`[corpus == "newspaper"])) #p = 0.01

res.ftest <- var.test(`%POS_VERB` ~ corpus, 
                      data = all_novels)

res.ftest #p = 0.1 > 0.05 ∴ no significant difference between the two variances - use t-Test

t.test(`%POS_VERB` ~ corpus, 
       data = all_novels, 
       var.equal = T)

plot(density(newsnovels$`%POS_VERB`))
plot(density(vicnovels$`%POS_VERB`))

cor(newsnovels$log_average_words, 
    newsnovels$`%POS_VERB`) 

cor(vicnovels$log_average_words, 
    vicnovels$`%POS_VERB`) 

lm_verbs_news <- lm(`%POS_VERB` ~ log_average_words,
                    data = subset(all_novels, 
                                  corpus == "newspaper"))
summary(lm_verbs_news)

lm_verbs_vic <- lm(`%POS_VERB` ~ log_average_words,
                    data = subset(all_novels, 
                                  corpus == "victorian"))
summary(lm_verbs_vic)

#plot

#verbs_avg <- 
ggplot(data = all_novels,
       aes(y = `%POS_VERB`,
           x = log_average_words)) +
  geom_point(data = subset(all_novels, 
                           corpus == "victorian"),
             aes(x = log_average_words,
                 y = `%POS_VERB`), 
             colour = "blue",
             alpha = 0.5) + 
  geom_point(data = subset(all_novels, 
                           corpus == "newspaper"),
             aes(x = log_average_words,
                 y = `%POS_VERB`), 
             colour = "red", 
             alpha = 0.5) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "newspaper"),
              aes(x = log_average_words,
                  y = `%POS_VERB`), 
              colour = "red",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "victorian"),
              aes(x = log_average_words,
                  y = `%POS_VERB`), 
              colour = "blue",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  #geom_text_repel(data = subset(all_novels, 
  #                              corpus == "newspaper" &
  #                                `%POS_VERB` > 15),
  #                aes(label = book_title)) +
  #geom_text_repel(data = subset(all_novels, 
  #                              corpus == "newspaper" &
  #                                `%POS_VERB` < 11),
  #                aes(label = book_title)) +
  theme_bw() + 
  labs(y = "% Verbs",
       x = "Average Words/Sentence",
       title = "Average Words/Sentence vs. % Verbs",
       colour = "Corpus")
  
#Nouns 
all_novels %>% 
  group_by(corpus) %>% 
  summarise(mean(`%POS_NOUN`))

with(all_novels, 
     shapiro.test(`%POS_NOUN`[corpus == "victorian"])) #p = 0.23
with(all_novels, 
     shapiro.test(`%POS_NOUN`[corpus == "newspaper"])) #p = 0.19

res.ftest <- var.test(`%POS_NOUN` ~ corpus, 
                      data = all_novels)
res.ftest #p = 0.01 < 0.05 ∴ significant difference between the two variances - use Wilcox Test 

wilcox.test(`%POS_NOUN` ~ corpus, 
            data = all_novels,
            exact = FALSE)

plot(density(newsnovels$`%POS_NOUN`))
plot(density(vicnovels$`%POS_NOUN`))

cor(newsnovels$log_average_words, 
    newsnovels$`%POS_NOUN`) 

cor(vicnovels$log_average_words, 
    vicnovels$`%POS_NOUN`) 

lm_nouns_news <- lm(`%POS_NOUN` ~ log_average_words,
                    data = subset(all_novels, 
                                  corpus == "newspaper"))
summary(lm_nouns_news)

lm_nouns_vic <- lm(`%POS_NOUN` ~ log_average_words,
                   data = subset(all_novels, 
                                 corpus == "victorian"))
summary(lm_nouns_vic)

#plot
nouns_avg <- 
ggplot(data = all_novels,
       aes(y = `%POS_NOUN`,
           x = log_average_words)) +
  geom_point(data = subset(all_novels, 
                           corpus == "victorian"),
             aes(x = log_average_words,
                 y = `%POS_NOUN`), 
             colour = "blue",
             alpha = 0.5) + 
  geom_point(data = subset(all_novels, 
                           corpus == "newspaper"),
             aes(x = log_average_words,
                 y = `%POS_NOUN`), 
             colour = "red", 
             alpha = 0.5) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "newspaper"),
              aes(x = log_average_words,
                  y = `%POS_NOUN`), 
              colour = "red",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "victorian"),
              aes(x = log_average_words,
                  y = `%POS_NOUN`), 
              colour = "blue",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  geom_text_repel(data = subset(all_novels, 
                                corpus == "newspaper" &
                                  `%POS_NOUN` > 18),
                  aes(label = book_title)) +
  theme_bw() + 
  labs(y = "% Nouns",
       x = "Average Words/Sentence",
       title = "Average Words/Sentence vs. % Nouns")

#Proper Nouns 
all_novels %>% 
  group_by(corpus) %>% 
  summarise(mean(`%POS_PROPN`))

with(all_novels, 
     shapiro.test(`%POS_PROPN`[corpus == "victorian"])) #p = 0.07
with(all_novels, 
     shapiro.test(`%POS_PROPN`[corpus == "newspaper"])) #p = 0.04

res.ftest <- var.test(`%POS_PROPN` ~ corpus, 
                      data = all_novels)

res.ftest #p = 0.01 < 0.05 ∴ significant difference between the two variances - use Wilcox Test

wilcox.test(`%POS_PROPN` ~ corpus, 
            data = all_novels,
            exact = FALSE)

plot(density(newsnovels$`%POS_PROPN`))
plot(density(vicnovels$`%POS_PROPN`))

cor(newsnovels$log_average_words, 
    newsnovels$`%POS_PROPN`) 

cor(vicnovels$log_average_words, 
    vicnovels$`%POS_PROPN`) 

lm_propn_news <- lm(`%POS_PROPN` ~ log_average_words,
                    data = subset(all_novels, 
                                  corpus == "newspaper"))
summary(lm_propn_news)

lm_propn_vic <- lm(`%POS_PROPN` ~ log_average_words,
                   data = subset(all_novels, 
                                 corpus == "victorian"))
summary(lm_propn_vic)

propns_avg <-
ggplot(data = all_novels,
       aes(y = `%POS_PROPN`,
           x = log_average_words)) +
  geom_point(data = subset(all_novels, 
                           corpus == "victorian"),
             aes(x = log_average_words,
                 y = `%POS_PROPN`), 
             colour = "blue",
             alpha = 0.5) + 
  geom_point(data = subset(all_novels, 
                           corpus == "newspaper"),
             aes(x = log_average_words,
                 y = `%POS_PROPN`), 
             colour = "red", 
             alpha = 0.5) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "newspaper"),
              aes(x = log_average_words,
                  y = `%POS_PROPN`), 
              colour = "red",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "victorian"),
              aes(x = log_average_words,
                  y = `%POS_PROPN`), 
              colour = "blue",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  geom_text_repel(data = subset(all_novels, 
                                corpus == "newspaper" &
                                  `%POS_PROPN` > 7.5),
                  aes(label = book_title)) +
  geom_text_repel(data = subset(all_novels, 
                                corpus == "newspaper" &
                                  `%POS_PROPN` < 1),
                  aes(label = book_title)) +
  theme_bw() + 
  labs(y = "% Proper Nouns",
       x = "Average Words/Sentence",
       title = "Average Words/Sentence vs. % Proper Nouns")

#Pronouns 
all_novels %>% 
  group_by(corpus) %>% 
  summarise(mean(`%POS_PRON`))

with(all_novels, 
     shapiro.test(`%POS_PRON`[corpus == "victorian"])) #p = 0.19
with(all_novels, 
     shapiro.test(`%POS_PRON`[corpus == "newspaper"])) #p = 0.97

res.ftest <- var.test(`%POS_PRON` ~ corpus, 
                      data = all_novels)

res.ftest #p = 0.05 = 0.05 ∴ significant difference between the two variances - use Wilcox Test

wilcox.test(`%POS_PRON` ~ corpus, 
            data = all_novels,
            exact = FALSE)

plot(density(newsnovels$`%POS_PRON`))
plot(density(vicnovels$`%POS_PRON`))

cor(newsnovels$log_average_words, 
    newsnovels$`%POS_PRON`) 

cor(vicnovels$log_average_words, 
    vicnovels$`%POS_PRON`) 

lm_pron_news <- lm(`%POS_PRON` ~ log_average_words,
                    data = subset(all_novels, 
                                  corpus == "newspaper"))
summary(lm_pron_news)

lm_pron_vic <- lm(`%POS_PRON` ~ log_average_words,
                   data = subset(all_novels, 
                                 corpus == "victorian"))
summary(lm_pron_vic)

#plot

pron_avg <- 
ggplot(data = all_novels,
       aes(y = `%POS_PRON`,
           x = log_average_words)) +
  geom_point(data = subset(all_novels, 
                           corpus == "victorian"),
             aes(x = log_average_words,
                 y = `%POS_PRON`), 
             colour = "blue",
             alpha = 0.5) + 
  geom_point(data = subset(all_novels, 
                           corpus == "newspaper"),
             aes(x = log_average_words,
                 y = `%POS_PRON`), 
             colour = "red", 
             alpha = 0.5) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "newspaper"),
              aes(x = log_average_words,
                  y = `%POS_PRON`), 
              colour = "red",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "victorian"),
              aes(x = log_average_words,
                  y = `%POS_PRON`), 
              colour = "blue",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  geom_text_repel(data = subset(all_novels, 
                                corpus == "newspaper" &
                                  `%POS_PRON` > 12.5),
                  aes(label = book_title)) +
  geom_text_repel(data = subset(all_novels, 
                                corpus == "newspaper" &
                                  `%POS_PRON` < 5),
                  aes(label = book_title)) +
  theme_bw() + 
  labs(y = "% Pronouns",
       x = "Average Words/Sentence",
       title = "Average Words/Sentence vs. % Pronouns")

#Adjectives 
all_novels %>% 
  group_by(corpus) %>% 
  summarise(mean(`%POS_ADJ`))

with(all_novels, 
     shapiro.test(`%POS_ADJ`[corpus == "victorian"])) #p = 0.08
with(all_novels, 
     shapiro.test(`%POS_ADJ`[corpus == "newspaper"])) #p = 0.32

res.ftest <- var.test(`%POS_ADJ` ~ corpus, 
                      data = all_novels)

res.ftest #p = 0.98 > 0.05 ∴ no significant difference between the two variances - use t-Test

t.test(`%POS_ADJ` ~ corpus, 
       data = all_novels,
       exact = FALSE)

plot(density(newsnovels$`%POS_ADJ`))
plot(density(vicnovels$`%POS_ADJ`))

cor(newsnovels$log_average_words, 
    newsnovels$`%POS_ADJ`) 

cor(vicnovels$log_average_words, 
    vicnovels$`%POS_ADJ`) 

lm_adj_news <- lm(`%POS_ADJ` ~ log_average_words,
                  data = subset(all_novels, 
                                corpus == "newspaper"))
summary(lm_adj_news)

lm_adj_vic <- lm(`%POS_ADJ` ~ log_average_words,
                 data = subset(all_novels, 
                               corpus == "victorian"))
summary(lm_adj_vic)

adj_avg <-
ggplot(data = all_novels,
       aes(y = `%POS_ADJ`,
           x = log_average_words)) +
  geom_point(data = subset(all_novels, 
                           corpus == "victorian"),
             aes(x = log_average_words,
                 y = `%POS_ADJ`), 
             colour = "blue",
             alpha = 0.5) + 
  geom_point(data = subset(all_novels, 
                           corpus == "newspaper"),
             aes(x = log_average_words,
                 y = `%POS_ADJ`), 
             colour = "red", 
             alpha = 0.5) + 
  geom_text_repel(data = subset(all_novels, 
                                 corpus == "newspaper" &
                                   `%POS_ADJ` > 7.5),
                                 aes(label = book_title)) +
  geom_text_repel(data = subset(all_novels, 
                                corpus == "newspaper" &
                                  `%POS_ADJ` < 5),
                  aes(label = book_title)) +
  geom_smooth(data = subset(all_novels, 
                            corpus == "newspaper"),
              aes(x = log_average_words,
                  y = `%POS_ADJ`), 
              colour = "red",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "victorian"),
              aes(x = log_average_words,
                  y = `%POS_ADJ`), 
              colour = "blue",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  theme_bw() + 
  labs(y = "% Adjectives",
       x = "Average Words/Sentence",
       title = "Average Words/Sentence vs. % Adjectives")

#plot all 

pos_avg_words_per_sentence <- 
  ((nouns_avg | adj_avg) /
     (propns_avg | pron_avg) /
     (verbs_avg)) +
  plot_layout(guides = "collect") +   
  theme(legend.position = "bottom")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = pos_avg_words_per_sentence,
       filename = "pos_avg_words_per_sentence.png",
       height = 40,
       width = 30,
       units = c("cm"))

#POS x POS ####

hist(all_novels$`%POS_ADJ`)
plot(density(all_novels$`%POS_ADJ`))
hist(all_novels$`%POS_NOUN`)
plot(density(all_novels$`%POS_NOUN`))
hist(all_novels$`%POS_VERB`)
plot(density(all_novels$`%POS_VERB`))

#Adjective x Noun
cor(all_novels$`%POS_ADJ`, 
    all_novels$`%POS_NOUN`) 

lm_adj_nouns <- lm(`%POS_ADJ` ~ `%POS_NOUN`,
                  data = all_novels)
summary(lm_adj_nouns)

adj_noun <- 
ggplot(all_novels,
       aes(x = `%POS_ADJ`,
           y = `%POS_NOUN`)) + 
  geom_point(aes(colour = corpus), 
             alpha = 0.5) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) +
  #geom_text_repel(data = subset(all_novels, 
  #                              corpus == "newspaper" &
  #                                `%POS_NOUN` > 17.5 |
  #                                corpus == "newspaper" &
  #                                `%POS_NOUN` < 13),
  #                aes(label = book_title)) +
  #geom_text_repel(data = subset(all_novels, 
  #                              corpus == "newspaper" &
  #                                `%POS_ADJ` < 5 |
  #                                corpus == "newspaper" &
  #                                `%POS_ADJ` > 7.5),
  #                aes(label = book_title)) +
  geom_smooth(colour = "black",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  theme_bw() + 
  labs(x = "% Adjectives",
       y = "% Nouns",
       title = "Adjectives x Nouns", 
       colour = "Corpus")

#Adjective x Verb
cor(all_novels$`%POS_ADJ`, 
    all_novels$`%POS_VERB`) 

lm_adj_verb <- lm(`%POS_ADJ` ~ `%POS_VERB`,
                   data = all_novels)
summary(lm_adj_verb)

adj_verb <- 
ggplot(all_novels,
       aes(x = `%POS_ADJ`,
           y = `%POS_VERB`)) + 
  geom_point(aes(colour = corpus), 
             alpha = 0.5) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) +
  #geom_text_repel(data = subset(all_novels, 
  #                              corpus == "newspaper" &
  #                                `%POS_ADJ` > 7.5 &
  #                                `%POS_VERB` > 15),
  #                aes(label = book_title)) +
  #geom_text_repel(data = subset(all_novels, 
  #                              corpus == "newspaper" &
  #                                `%POS_ADJ` < 5 &
  #                                `%POS_VERB` < 12),
  #               aes(label = book_title)) +
  geom_smooth(colour = "black",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  theme_bw() + 
  labs(x = "% Adjectives",
       y = "% Verbs",
       title = "Adjectives x Verbs",
       colour = "Corpus")

#Noun x Verb
cor(all_novels$`%POS_NOUN`, 
    all_novels$`%POS_VERB`) 

lm_noun_verb <- lm(`%POS_NOUN` ~ `%POS_VERB`,
                   data = all_novels)
summary(lm_noun_verb)

noun_verb <- 
ggplot(all_novels,
       aes(x = `%POS_NOUN`,
           y = `%POS_VERB`)) + 
  geom_point(aes(colour = corpus), 
             alpha = 0.5) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) +
  geom_smooth(colour = "black",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  theme_bw() + 
  labs(x = "% Nouns",
       y = "% Verbs",
       title = "Noun x Verbs", 
       colour = "Corpus")

#Pronoun x Verb
cor(all_novels$`%POS_PRON`, 
    all_novels$`%POS_VERB`) 

lm_pron_verb <- lm(`%POS_PRON` ~ `%POS_VERB`,
                   data = all_novels)
summary(lm_pron_verb) #non-significant

#Pronoun x Adjective
cor(all_novels$`%POS_PRON`, 
    all_novels$`%POS_ADJ`) 

lm_pron_adj <- lm(`%POS_PRON` ~ `%POS_ADJ`,
                   data = all_novels)
summary(lm_pron_adj) #significant 

pron_adj <- 
ggplot(all_novels,
       aes(x = `%POS_PRON`,
           y = `%POS_ADJ`)) + 
  geom_point(aes(colour = corpus), 
             alpha = 0.5) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) +
  geom_smooth(colour = "black",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  theme_bw() + 
  labs(x = "% Pronouns",
       y = "% Adjectives",
       title = "Pronouns x Adjectives",
       colour = "Corpus")

pron_adj_2 <- 
  ggplot(all_novels,
         aes(x = `%POS_PRON`,
             y = `%POS_ADJ`)) + 
  geom_point(aes(colour = corpus), 
             alpha = 0.5) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "newspaper"),
              colour = "red",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) +
  geom_smooth(data = subset(all_novels, 
                            corpus == "victorian"),
              colour = "blue",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) +
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(x = "% Pronouns",
       y = "% Adjectives",
       title = "Pronouns x Adjectives",
       colour = "Corpus")

#Pronoun x Nouns
cor(all_novels$`%POS_PRON`, 
    all_novels$`%POS_NOUN`) 

lm_pron_noun <- lm(`%POS_PRON` ~ `%POS_NOUN`,
                  data = all_novels)
summary(lm_pron_noun) #significant 

pron_noun <- 
ggplot(all_novels,
       aes(x = `%POS_PRON`,
           y = `%POS_NOUN`)) + 
  geom_point(aes(colour = corpus), 
             alpha = 0.5) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) +
  geom_smooth(colour = "black",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  theme_bw() + 
  labs(x = "% Pronouns",
       y = "% Nouns",
       title = "Pronouns x Nouns", 
       colour = "Corpus")

pron_noun_2 <- 
ggplot(all_novels,
       aes(x = `%POS_PRON`,
           y = `%POS_NOUN`)) + 
  geom_point(aes(colour = corpus), 
             alpha = 0.5) + 
  geom_smooth(data = subset(all_novels, 
                            corpus == "newspaper"),
              colour = "red",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) +
  geom_smooth(data = subset(all_novels, 
                            corpus == "victorian"),
              colour = "blue",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) +
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(x = "% Pronouns",
       y = "% Nouns",
       title = "Pronouns x Nouns",
       colour = "Corpus")

#Proper Noun x Verb
cor(all_novels$`%POS_PROPN`, 
    all_novels$`%POS_VERB`) 

lm_propn_verb <- lm(`%POS_PROPN` ~ `%POS_VERB`,
                    data = all_novels)
summary(lm_propn_verb) #significant 

propn_verb <-
ggplot(all_novels,
       aes(x = `%POS_PROPN`,
           y = `%POS_VERB`)) + 
  geom_point(aes(colour = corpus), 
             alpha = 0.5) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) +
  geom_smooth(colour = "black",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  theme_bw() + 
  labs(x = "% Proper Nouns",
       y = "% Verbs",
       title = "Proper Nouns x Verbs",
       colour = "Corpus")

#Proper Noun x Adjective
cor(all_novels$`%POS_PROPN`, 
    all_novels$`%POS_ADJ`) 

lm_propn_adj <- lm(`%POS_PROPN` ~ `%POS_ADJ`,
                    data = all_novels)
summary(lm_propn_adj) #non-significant 

#Proper Noun x Adjective
cor(all_novels$`%POS_PROPN`, 
    all_novels$`%POS_NOUN`) 

lm_propn_noun <- lm(`%POS_PROPN` ~ `%POS_NOUN`,
                   data = all_novels)
summary(lm_propn_noun) #significant 

propn_noun <-
ggplot(all_novels,
       aes(x = `%POS_PROPN`,
           y = `%POS_NOUN`)) + 
  geom_point(aes(colour = corpus), 
             alpha = 0.5) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) +
  geom_smooth(colour = "black",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) + 
  theme_bw() + 
  labs(x = "% Proper Nouns",
       y = "% Nouns",
       title = "Proper Nouns x Nouns",
       colour = "Corpus")

#Proper Noun x Pronoun
cor(all_novels$`%POS_PROPN`, 
    all_novels$`%POS_PRON`) 

lm_propn_pron <- lm(`%POS_PROPN` ~ `%POS_PRON`,
                    data = all_novels)
summary(lm_propn_pron) #significant 

propn_pron <- 
ggplot(all_novels,
       aes(x = `%POS_PROPN`,
           y = `%POS_PRON`)) + 
  geom_point(aes(colour = corpus), 
             alpha = 0.5) + 
  geom_smooth(colour = "black",
              linetype = "dashed",
              size = 0.5,
              method = "lm",
              se = F) +
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(x = "% Proper Nouns",
       y = "% Pronouns",
       title = "Proper Nouns x Pronouns",
       colour = "Corpus")

#plot all 

pos_x_pos_by_corpus <- 
  ((adj_noun | adj_verb) /
     (noun_verb | pron_adj) /
     (pron_noun | propn_verb) /
     (propn_noun | propn_pron)) +
  plot_layout(guides = "collect") +   
  theme(legend.position = "bottom") 

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = pos_x_pos_by_corpus,
       filename = "pos_x_pos_by_corpus.png",
       height = 40,
       width = 30,
       units = c("cm"))

pronouns_2 <- 
  ggpubr::ggarrange(pron_noun_2,
                    pron_adj_2, 
                    ncol = 1,
                    align = "v", 
                    common.legend = T,
                    legend = "bottom")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = pronouns_2,
       filename = "pronouns_2.png",
       height = 30,
       width = 30,
       units = c("cm"))

#3D
library(rgl)

plot3d(
  x = all_novels$`%POS_NOUN`,
  y = all_novels$`%POS_VERB`,
  z = all_novels$`%POS_ADJ`,
  colvar = as.numeric(all_novels$corpus),
  col = c("red", "blue"),
  type = 's', 
  radius = .1,
  xlab="% Nouns", ylab="% Verbs", zlab="% Adjectives") + 
  identify3d(x = all_novels$`%POS_NOUN`,
         y = all_novels$`%POS_VERB`,
         z = all_novels$`%POS_ADJ`,
         all_novels$book_title)


#Other Metadata ####

#for labelling boxplot outliers 
is_outlier <- function(x) {
  return(x < quantile(x, 0.25) - 1.5 * IQR(x) | x > quantile(x, 0.75) + 1.5 * IQR(x))
}

#for labelling gender
labels_gender <- c(female = "Female", male = "Male")
labels_voice <- c(first = "First", third = "Third")

#GENDER####
titles_by_gender <- #count titles by gender
  all_novels %>% 
  group_by(gender, corpus) %>% 
  count()

#Gender x POS

#Pronouns
all_novels %>% 
  group_by(corpus, gender) %>% 
  summarise(mean(`%POS_PRON`))

aov.pron.gc <- 
  aov(`%POS_PRON` ~ gender * corpus,
      all_novels)

summary.aov(aov.pron.gc)

all_novels %>%
  group_by(gender,corpus) %>%
  mutate(outlier = ifelse(is_outlier(`%POS_PRON`), 
                          book_title, 
                          as.character(NA))) %>% 
  ggplot(., 
         aes(x = corpus,
             y = `%POS_PRON`)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_wrap(.~gender,
             labeller = labeller(gender = labels)) + 
  #geom_text(aes(label = outlier), 
  #          na.rm = TRUE, 
  #          hjust = +0.5,
  #          vjust = -1,
  #          size = 3) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() +
  labs(title = "% Pronouns (by corpus, gender)", 
       x = "Corpus",
       y = "% Pronouns")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "box_pos_pron_gender.png",
       height = 15,
       width = 15,
       units = c("cm"))

#Verbs

all_novels %>% 
  group_by(corpus, gender) %>% 
  summarise(mean(`%POS_VERB`))

aov.verb.gc <- 
  aov(`%POS_VERB` ~ gender * corpus,
      all_novels)

summary.aov(aov.verb.gc)
TukeyHSD(aov.verb.gc)

all_novels %>%
  group_by(gender,corpus) %>%
  mutate(outlier = ifelse(is_outlier(`%POS_VERB`), 
                          book_title, 
                          as.character(NA))) %>% 
  ggplot(., 
         aes(x = corpus,
             y = `%POS_VERB`)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_wrap(.~gender,
             labeller = labeller(gender = labels)) + 
  #geom_text_repel(aes(label = outlier), 
  #          na.rm = TRUE, 
  #          #hjust = +0.5,
  #          #vjust = -1,
  #          size = 3) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() +
  labs(title = "% Verbs (by corpus, gender)", 
       x = "Corpus",
       y = "% Verbs")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "box_pos_verb_gender.png",
       height = 15,
       width = 15,
       units = c("cm"))

#Nouns 

all_novels %>% 
  group_by(corpus, gender) %>% 
  summarise(mean(`%POS_NOUN`))

aov.noun.gc <- 
  aov(`%POS_NOUN` ~ gender * corpus,
      all_novels)

summary.aov(aov.noun.gc)

all_novels %>%
  group_by(gender,corpus) %>%
  mutate(outlier = ifelse(is_outlier(`%POS_NOUN`), 
                          book_title, 
                          as.character(NA))) %>% 
  ggplot(., 
         aes(x = corpus,
             y = `%POS_NOUN`)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_wrap(.~gender,
             labeller = labeller(gender = labels)) + 
  #geom_text_repel(aes(label = outlier), 
  #                na.rm = TRUE, 
  #                #hjust = +0.5,
  #                #vjust = -1,
  #                size = 3) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(title = "% Nouns (by corpus, gender)", 
       x = "",
       y = "% Nouns",
       colour = "Corpus")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "box_pos_noun_gender.png",
       height = 15,
       width = 15,
       units = c("cm"))

#Adjectives

all_novels %>% 
  group_by(corpus, gender) %>% 
  summarise(mean(`%POS_ADJ`))

aov.adj.gc <- 
  aov(`%POS_ADJ` ~ gender * corpus,
      all_novels)

summary.aov(aov.adj.gc)

all_novels %>%
  group_by(gender,corpus) %>%
  mutate(outlier = ifelse(is_outlier(`%POS_ADJ`), 
                          book_title, 
                          as.character(NA))) %>% 
  ggplot(., 
         aes(x = corpus,
             y = `%POS_ADJ`)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_wrap(.~gender,
             labeller = labeller(gender = labels)) + 
  #geom_text_repel(aes(label = outlier), 
  #                na.rm = TRUE, 
  #                #hjust = +0.5,
  #                #vjust = -1,
  #                size = 3) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(title = "% Adjectives (by corpus, gender)", 
       x = "Corpus",
       y = "% Adjectives",
       colour = "Corpus")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "box_pos_adj_gender.png",
       height = 15,
       width = 15,
       units = c("cm"))

#Proper Nouns
all_novels %>% 
  group_by(corpus, gender) %>% 
  summarise(mean(`%POS_PROPN`))

aov.propn.gc <- 
  aov(`%POS_PROPN` ~ gender * corpus,
      all_novels)

summary.aov(aov.propn.gc)

all_novels %>%
  group_by(gender,corpus) %>%
  mutate(outlier = ifelse(is_outlier(`%POS_PROPN`), 
                          book_title, 
                          as.character(NA))) %>% 
  ggplot(., 
         aes(x = corpus,
             y = `%POS_PROPN`)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_wrap(.~gender,
             labeller = labeller(gender = labels)) + 
  #geom_text_repel(aes(label = outlier), 
  #                na.rm = TRUE, 
  #                #hjust = +0.5,
  #                #vjust = -1,
  #                size = 3) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(title = "% Proper Nouns (by corpus, gender)", 
       x = "Corpus",
       y = "% Proper Nouns")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "box_pos_propn_gender.png",
       height = 15,
       width = 15,
       units = c("cm"))

#Plot All

pos_novels <-
  all_novels %>% 
  gather(key = "pos",value = "pcent", 36:50) %>% 
  filter(pos == "%POS_ADJ" |
           pos == "%POS_PRON" |
           pos == "%POS_PROPN" |
           pos == "%POS_NOUN" |
           pos == "%POS_VERB")

ggplot(data = pos_novels,
       aes(x = corpus, 
           y = pcent)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_grid(pos~gender) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(title = "% Parts of Speech (by corpus, gender)", 
       x = "Corpus",
       y = "% Part of Speech")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "box_pos_all_gender.png",
       height = 50,
       width = 20,
       units = c("cm"))

#VOICE####
titles_by_voice <- #count titles by voice
  all_novels %>% 
  group_by(person, corpus) %>% 
  count()

#Voice x POS

#Pronouns
all_novels %>% 
  group_by(corpus, person) %>% 
  summarise(mean(`%POS_PRON`))

aov.pron.vc <- 
  aov(`%POS_PRON` ~ person * corpus,
      all_novels)

summary.aov(aov.pron.vc)

all_novels %>%
  group_by(person,corpus) %>%
  mutate(outlier = ifelse(is_outlier(`%POS_PRON`), 
                          book_title, 
                          as.character(NA))) %>% 
  ggplot(., 
         aes(x = corpus,
             y = `%POS_PRON`)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_wrap(.~person,
             labeller = labeller(person = labels_voice)) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(title = "% Pronouns (by corpus, voice)", 
       x = "Corpus",
       y = "% Pronouns")

#Verbs
all_novels %>% 
  group_by(corpus, person) %>% 
  summarise(mean(`%POS_VERB`))

aov.verb.vc <- 
  aov(`%POS_VERB` ~ person * corpus,
      all_novels) 

summary.aov(aov.verb.vc)

all_novels %>%
  group_by(person,corpus) %>%
  mutate(outlier = ifelse(is_outlier(`%POS_VERB`), 
                          book_title, 
                          as.character(NA))) %>% 
  ggplot(., 
         aes(x = corpus,
             y = `%POS_VERB`)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_wrap(.~person,
             labeller = labeller(person = labels_voice)) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(title = "% Verbs (by corpus, voice)", 
       x = "Corpus",
       y = "% Verbs")

#Nouns
all_novels %>% 
  group_by(corpus, person) %>% 
  summarise(mean(`%POS_NOUN`))

aov.noun.vc <- 
  aov(`%POS_NOUN` ~ person * corpus,
      all_novels)

summary.aov(aov.noun.vc)

all_novels %>%
  group_by(person,corpus) %>%
  mutate(outlier = ifelse(is_outlier(`%POS_NOUN`), 
                          book_title, 
                          as.character(NA))) %>% 
  ggplot(., 
         aes(x = corpus,
             y = `%POS_NOUN`)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_wrap(.~person,
             labeller = labeller(person = labels_voice)) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(title = "% Nouns (by corpus, voice)", 
       x = "Corpus",
       y = "% Nouns")

#Adjectives
all_novels %>% 
  group_by(corpus, person) %>% 
  summarise(mean(`%POS_ADJ`))

aov.adj.vc <- 
  aov(`%POS_ADJ` ~ person * corpus,
      all_novels)

summary.aov(aov.adj.vc)

all_novels %>%
  group_by(person,corpus) %>%
  mutate(outlier = ifelse(is_outlier(`%POS_ADJ`), 
                          book_title, 
                          as.character(NA))) %>% 
  ggplot(., 
         aes(x = corpus,
             y = `%POS_ADJ`)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_wrap(.~person,
             labeller = labeller(person = labels_voice)) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(title = "% Adjectives (by corpus, voice)", 
       x = "Corpus",
       y = "% Adjectives")

#Proper Nouns
all_novels %>% 
  group_by(corpus, person) %>% 
  summarise(mean(`%POS_PROPN`))

aov.propn.vc <- 
  aov(`%POS_PROPN` ~ person * corpus,
      all_novels)

summary.aov(aov.propn.vc)

all_novels %>%
  group_by(person,corpus) %>%
  mutate(outlier = ifelse(is_outlier(`%POS_PROPN`), 
                          book_title, 
                          as.character(NA))) %>% 
  ggplot(., 
         aes(x = corpus,
             y = `%POS_PROPN`)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_wrap(.~person,
             labeller = labeller(person = labels_voice)) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(title = "% Proper Nouns (by corpus, voice)", 
       x = "Corpus",
       y = "% Proper Nouns")

#Plot All

pos_novels <-
  all_novels %>% 
  gather(key = "pos",value = "pcent", 36:50) %>% 
  filter(pos == "%POS_ADJ" |
           pos == "%POS_PRON" |
           pos == "%POS_PROPN" |
           pos == "%POS_NOUN" |
           pos == "%POS_VERB")

ggplot(data = pos_novels,
       aes(x = corpus, 
           y = pcent)) + 
  geom_boxplot(aes(colour = corpus)) + 
  facet_grid(pos~person) + 
  scale_colour_manual(values = c("red","blue"),
                      labels = c("Newspaper", "Victorian"),
                      guide = "none") + 
  scale_x_discrete(labels=c("Newspaper", "Victorian")) +
  theme_bw() + 
  labs(title = "% Parts of Speech (by corpus, voice)", 
       x = "Corpus",
       y = "% Part of Speech")

ggsave(path = "/Users/ronny/Desktop/Newspaper Novel Plots/POS, Stats", 
       plot = last_plot(),
       filename = "box_pos_all_voice.png",
       height = 50,
       width = 20,
       units = c("cm"))

##########UNUSED########## ####
#POS by Year/Decade ####

all_novels$book_year <- as.numeric(all_novels$book_year)

plot(density(all_novels$log_stopless))
cor(all_novels$log_stopless, 
    all_novels$book_year) 

#Total Words by Year
ggplot(data = all_novels,
       aes(y = words_count_stopless,
           x = book_year)) +
  geom_point(aes(colour = corpus)) + 
  geom_smooth(aes(colour = corpus),
              se = F
              #,method = "lm"
  ) + 
  geom_smooth(se = F, 
              color = "black"
              #,method = "lm"
  )

#Verbs
plot(density(all_novels$`%POS_VERB`)) #density plot
cor(all_novels$`%POS_VERB`, 
    all_novels$book_year) 

ggplot(data = all_novels,
       aes(y = `%POS_VERB`,
           x = book_year)) +
  geom_point(aes(colour = corpus)) + 
  geom_smooth(aes(colour = corpus),
              se = F,
              method = "lm") + 
  geom_smooth(se = F, 
              color = "black",
              method = "lm")

#Nouns
plot(density(all_novels$`%POS_NOUN`)) #density plot
cor(all_novels$`%POS_NOUN`, 
    all_novels$book_year) 

ggplot(data = all_novels,
       aes(y = `%POS_NOUN`,
           x = book_year)) +
  geom_point(aes(colour = corpus))+ 
  geom_point(aes(colour = corpus)) + 
  geom_smooth(aes(colour = corpus),
              se = F) + 
  geom_smooth(se = F, 
              color = "black")

#Adjectives
ggplot(data = all_novels,
       aes(y = `%POS_ADJ`,
           x = book_year)) +
  geom_point(aes(colour = corpus))+ 
  geom_point(aes(colour = corpus)) + 
  geom_smooth(aes(colour = corpus),
              se = F) + 
  geom_smooth(se = F, 
              color = "black")

#Adverbs 
ggplot(data = all_novels,
       aes(y = `%POS_ADV`,
           x = book_year)) +
  geom_point(aes(colour = corpus))+ 
  geom_point(aes(colour = corpus)) + 
  geom_smooth(aes(colour = corpus),
              se = F) + 
  geom_smooth(se = F, 
              color = "black")


pos_novels <-
  all_novels %>% 
  gather(key = "pos",value = "pcent", 36:49) %>% 
  filter(pos == "%POS_ADJ" |
           pos == "%POS_PRON" |
           pos == "%POS_PROPN" |
           pos == "%POS_NOUN" |
           pos == "%POS_VERB")

ggplot(pos_novels,
       aes(x = year,
           y = pcent)) + 
  geom_point(aes(colour = corpus)) + 
  facet_wrap(.~pos)

pos_by_decade <-
  all_novels %>% 
  group_by(decade, corpus) %>% 
  summarise(m_adj = mean(`%POS_ADJ`),
            m_pron = mean(`%POS_PRON`),
            m_propn = mean(`%POS_PROPN`),
            m_noun = mean(`%POS_NOUN`),
            m_verb = mean(`%POS_VERB`)) %>% 
  gather(key = "pos",value = "pcent", 3:7)

ggplot(pos_by_decade,
       aes(x = decade,
           y = pcent,
           colour = corpus)) +
  geom_point() + 
  geom_line(aes(group = corpus)) + 
  theme_bw() + 
  facet_wrap(.~pos, 
             ncol = 1)

ggplot(data = pos_novels,
       aes(x = year,
           y = pcent,
           colour = pos)) +
  geom_point() + 
  geom_smooth(method = "gam") + 
  theme_bw() + 
  facet_wrap(.~corpus)