import random
sample_dates = []
for year in range(1840,1860):
    for month in range(1, 12):
        for i in range(0, 10):
            sample_day = random.randint(1, 30)
            sample_date = f"{year}-{month}-{sample_day}.txt"
            f = open(sample_date, 'w')
            f.write(f'random stuff - {sample_date}')
            f.close()