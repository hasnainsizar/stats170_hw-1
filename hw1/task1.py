import pandas as pd
import glob

csv_file = sorted(glob.glob("*.csv"))

for file in csv_file:
    df = pd.read_csv(file, low_memory=False)
    # 1
    print(f"\nFile: {file}")
    print(f"Number of rows: {len(df)}")
    print(f"Number of columns: {len(df.columns)}")
    print(f"Column names: {list(df.columns)}")
    
    # 2
    df_missing = (df.isna().mean() * 100).sort_values(ascending=False)
    df_missing = df_missing[df_missing > 0]

    print("\nMissing columns and their missing percentages:")
    if df_missing.empty:
        print("None")
    else:
        print(df_missing.round(2).to_string())

    # 3
    str_cols = [col for col in df.columns if df[col].dtype == 'object']
    if str_cols:
        print("\nString columns and their structure:")
        for col in str_cols:
            sample_values = df[col].dropna().astype(str).head(10).tolist()
            print(f"Column: {col}")
            print(f"Sample values: {sample_values}")
    