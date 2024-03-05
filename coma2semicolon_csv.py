import pandas as pd
input_file = 'users_usa.csv'
output_file = 'users_usa-2.csv'
df = pd.read_csv(input_file, sep=',', quotechar='"')
df.to_csv(output_file, sep=';', index=False)
