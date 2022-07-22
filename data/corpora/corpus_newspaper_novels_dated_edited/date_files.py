import os

os.chdir('/home/lyre/git_projects/work/ciphersofthetimes/data/corpora/corpus_newspaper_novels_dated/')
print(os.getcwd())
count = 0
dates = ["1847", "1864", "1863", "1883", "1867", "1853", "1864", "1841", "1892", "1876", "1850", "1871", "1848", "1897", "1860", "1874", "1868", "1866", "1898", "1863", "1854", "1899", "1864", "1894", "1862", "1895", "1862", "1862", "1844", "1863", "1846", "1884", "1814", "1848", "1888", "1871", "1862", "1828", "1865", "1818", "1886", "1874", "1849", "1866", "1916", "1864", "1893", "1864", "1901", "1852", "1910", "1888", "1907", "1868", "1886", "1873", "1903", "1837", "1888", "1894", "1861", "1855", "1859", "1892", "1909", "1882", "1867", "1911", "1853", "1863",]
for file_name in sorted(os.listdir(".")):
    # double check that these are text files
    if file_name.endswith(".txt"):
        if file_name.startswith("."):
            print(f"hidden file: {file_name}")
            continue
        
        # new_file_name = file_name.split('_')[0] + ".txt"
        # date = dates[count]
        new_file_name = file_name.split(".")[0]
        new_file_name = new_file_name.replace(' ', '_')
        new_file_name = new_file_name + "_" + dates[count] + ".txt"

        print(f"{count}: new_name: {new_file_name}")
        count += 1
        
        os.rename(file_name, new_file_name)