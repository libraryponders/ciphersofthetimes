import os

# os.chdir('data/corpora/corpus_newspaper_novels_dated')
print(os.getcwd())
count = 0
for file_name in sorted(os.listdir(".")):
    if file_name.endswith(".txt"):
        count += 1
        new_file_name = file_name.split("_1")[:-1]
        new_file_name = " ".join(new_file_name)
        new_file_name = new_file_name.replace("_", " ")
        print(new_file_name)

print(count)

string1 = """
removed = 
Bleak House
Cecil, or the Adventures of a Coxcomb
// Hard Times
Heart of Darkness
Mansfield Park 
// MiddleMarch
Oliver Twist
Persuasion
The First Men in the Moon 
The Heir of Redclyffe 
The Mirror of the Sea
Villette
"""