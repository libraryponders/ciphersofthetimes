<h2 style="text-align: center;">Ciphers of <em>the Times</em> - Computational Analysis of Newspapers and Newspaper Novels in 19th-century England</h2>
<p></p>
<p>Ciphers of the Times is a research project housed in McGill University Library which uses computational text analysis to explore the Agony Columns of the Times and related fictional novels from the period.</p>
<p>This GitHub repository contains the code and data used throughout our research project, and serves as the basis for an upcoming exhibition on the subject housed at McGill University Library.</p>

<p>Most of this project consists of jupyter notebooks running a Python 3 kernel, but includes some analysis and visualization in R as well. Initial data input and preprocessing was conducted with the pandas library. Our TTR and MATTR analysis employs the lexicalrichness library, while POS (Part of speech) tagging was run using the spacy library. Our initial visualizations draw on the matplotlib library, and our topic model uses the nltk for bigrams and trigrams, then employing the gensim ldamodel for output.</p>


<p>Our repository file structure:</p>
<pre class="chroma" tabindex="0"><code class="language-markdown" data-lang="markdown">

├── README.md
├── assets
│   ├── all_characters_and_numbers_to_exclude.txt
│   ├── characters_and_numbers_to_exclude.txt
│   ├── stopall.txt
│   ├── stopnames.txt
│   └── stopwords.txt
├── data
│   ├── corpora
│   │   └── corpus_newspaper_novels
│   │       └── *all_newspaper_novels_as_text_files
│   └── spreadsheets
│       ├── clean_text_nnovels_for_tm.csv
│       ├── clean_text_nnovels_for_tm_filtered.csv
│       ├── df_nnovels_meta.csv
│       ├── df_txtlab_meta.csv
│       ├── df_nnovels_full.csv**
│       ├── df_txtlab_full.csv**
│       ├── final_texts_for_TM.csv
│       └── nnovels_corpus_metadata.csv
├── notebooks
│   ├── newspapers-analysis
│   │   └── XMLnewspaperparser-2022-02-02.ipynb
│   └── novels-analysis
│       ├── Newpaper_Novels_Topic_Modeling_master.ipynb
│       ├── Newspaper_Novels_Project_Notebook.ipynb
│       ├── Newspaper_Novels_Visalizations.ipynb
│       └── Newspaper_Novels_and_Victorian_Novels_Output_Analysis copy.R
│       
└── output
    ├── Newspaper-Novels-and-txtLAB-comparisons-2022-03-15.docx
     └── lda-output-2022-03-23
        └── *all_lda_output_files
</code>

<p></p>
<p>This project is an ongoing effort conducted by students and library staff at McGill University Library.</p>

<p>Principal Investigator: Professor Nathalie Cooke
Project Manager and Lead Python: Leehu Sigler
Project Coordinator and Lead R: Ronny Litvack-Katzman
Research Assistant (Data Analysis): Lillian Simons
Research Assistant (Researcher, Narrative Design): Rosalia Poplawski
Research Assistant (Researcher, Graphic Design): Bianca Tri</p>