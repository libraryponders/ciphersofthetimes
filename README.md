<h2 style="text-align: center;">Ciphers of <em>the Times</em> - Computational Analysis of Newspapers and Newspaper Novels in 19th-century England</h2>
<p></p>
<p>Ciphers of the Times is a research project housed in McGill University Library which uses computational text analysis to explore the Agony Columns of the Times and related fictional novels from the period.</p>
<p>This GitHub repository contains the code and data used throughout our research project, and serves as the basis for an upcoming exhibition on the subject housed at McGill University Library.</p>
<p>Our repository file structure:</p>
<pre class="chroma" tabindex="0"><code class="language-markdown" data-lang="markdown">
├── assets
│   ├── all_characters_and_numbers_to_exclude.txt
│   ├── characters_and_numbers_to_exclude.txt
│   ├── stopall.txt
│   ├── stopnames.txt<br />│   ├── stopwords.txt
├── data
│   ├── corpora
│   │   ├── <span class="ge">corpus_newspaper_novels<br />│   │       ├── *all_project_novels_as_txt_files</span>
│   ├── spreadsheets<br />│   │   ├── <span class="ge">df_nnovels_meta.csv<br /></span>│   │   ├── <span class="ge">df_txtlab_meta.csv<br />│   │   ├── df_nnovels_full.csv**<br />│   │   ├── df_txtlab_full.csv**<br />│   │   ├── df_nnovels_meta.csv<br />│   │   ├── nnovels_corpus_metadata.csv<br /></span><span class="ge">│   │   ├── clean_text_nnovels_for_tm.csv<br />│   │   ├── clean_text_nnovels_for_tm_filtered.csv</span>
├── notebooks
├── output
└── .gitignore</code></pre>
<p></p>