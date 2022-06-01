
![Logo](https://libraryponders.github.io/assets/img/website_logo_new_450.png)


# Ciphers of _the Times_ - Computational Analysis of Newspapers and Newspaper Novels from 19th-century England

Ciphers of the Times is a research project housed in McGill University Library 
which uses computational text analysis to explore the 
Agony Columns of the Times and related fictional novels 
from the period.

This GitHub repository contains the code and data used throughout 
our research project, and serves as the basis for an upcoming exhibition 
on the subject housed at McGill University Library.

Most of this project consists of jupyter notebooks and .py files running a 
Python 3 kernel, but includes some analysis and 
visualization in R as well. Classification models are to be conducted in R.
Initial data input and preprocessing was conducted with the pandas 
library. Our TTR and MATTR analysis employs the lexicalrichness library, 
while POS (Part of speech) tagging was run using the spacy library. 
Initial visualizations draw on the matplotlib library, 
and our topic model uses the nltk for bigrams and trigrams, 
then employing the gensim ldamodel for output.


## Usage/Examples

Although anyone is more than welcome to use the notebooks 
and scripts used throughout the project,
perhaps of most interest would be to examine the output
data we have collected over the past year.
This includes metadata for nearly 150 Victorian novels,
as well as other information such as TTR, MATTR, raw statistics,
POS tagging, and Topic Modeling results. Raw newspaper data is currently
being processed and will be uploaded, if possible, when 
they are available. 

All output data frames are saved in the "spreadsheets" folder,
which includes complete data frames for the two novel corpora
used (one from .txtLAB, one we collected ourselves), as well as
data frames diving into specific period novels, to examine formal
variations throughout the novels, such as changes to dialogue/narration
ratios and significant differences in the use of verbs, nouns, pronouns,
and proper nouns. 

Visualizations are forthcoming for both axes of analysis, the Victorian novels
and the Victorian newspapers, to be presented as an exhibition
at McGill University Library in 2023. 



## Repo Authors

- Leehu Ben Sigler
- Ronny Litvak-Katzman
- Lillian Simons
## Project Members

- Principal Investigator: Professor Nathalie Cooke
- Project Manager and Lead Python: Leehu Sigler
- Project Coordinator and Lead R: Ronny Litvack-Katzman
- Research Assistant (Data Analysis): Lillian Simons
- Research Assistant (Researcher, Narrative Design): Rosalia Poplawski
- Research Assistant (Researcher, Graphic Design): Bianca Tri

## Acknowledgements

 - With thanks to .txtLAB for making their Novel450 data available, which we have used throughout the project.
 
 *** This project is funded by the Social Sciences and Humanities Research Council of Canada.