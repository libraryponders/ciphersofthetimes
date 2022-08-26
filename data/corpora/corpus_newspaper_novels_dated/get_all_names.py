import os

# os.chdir('data/corpora/corpus_newspaper_novels_dated')
print(os.getcwd())
for file_name in sorted(os.listdir(".")):
    if file_name.endswith(".txt"):
        new_file_name = file_name.split("_1")[:-1]
        new_file_name = " ".join(new_file_name)
        new_file_name = new_file_name.replace("_", " ")
        print(new_file_name)