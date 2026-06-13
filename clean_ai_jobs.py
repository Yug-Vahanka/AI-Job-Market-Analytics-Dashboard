"""
AI Job Market Analytics Dashboard
Step 2: Data Cleaning Script
Author: Project Build
"""

import pandas as pd
import numpy as np

print("=" * 50)
print("  AI Jobs Data Cleaning Pipeline")
print("=" * 50)

# ── Load ──────────────────────────────────────────
df = pd.read_csv("/home/claude/ai_jobs_raw.csv")
print(f"\n[1] Raw dataset: {df.shape[0]:,} rows × {df.shape[1]} columns")
print(f"    Missing values:\n{df.isnull().sum()[df.isnull().sum()>0]}")

# ── Remove duplicates ─────────────────────────────
before = len(df)
df.drop_duplicates(inplace=True)
print(f"\n[2] Removed {before - len(df)} duplicate rows")

# ── Fix data types ────────────────────────────────
df["posted_date"] = pd.to_datetime(df["posted_date"])
df["salary_usd"] = pd.to_numeric(df["salary_usd"], errors="coerce")
print(f"\n[3] Fixed data types: posted_date → datetime, salary_usd → numeric")

# ── Handle missing salaries ───────────────────────
median_by_title = df.groupby("job_title")["salary_usd"].median()
missing_mask = df["salary_usd"].isnull()
df.loc[missing_mask, "salary_usd"] = df.loc[missing_mask, "job_title"].map(median_by_title)
df["salary_usd"] = df["salary_usd"].astype(int)
print(f"\n[4] Filled {missing_mask.sum()} missing salaries with per-title median")

# ── Standardise experience labels ─────────────────
exp_map = {"EN":"Entry","MI":"Mid","SE":"Senior","EX":"Lead"}
df["experience_level"] = df["experience_level"].replace(exp_map)
print(f"\n[5] Experience levels: {df['experience_level'].unique().tolist()}")

# ── Add derived columns ───────────────────────────
df["salary_band"] = pd.cut(
    df["salary_usd"],
    bins=[0, 70000, 100000, 130000, 160000, 999999],
    labels=["<70K", "70-100K", "100-130K", "130-160K", "160K+"]
)
print(f"\n[6] Added salary_band column")

# ── Save cleaned main file ────────────────────────
df.to_csv("/home/claude/cleaned_ai_jobs.csv", index=False)
print(f"\n[7] Saved: cleaned_ai_jobs.csv ({len(df):,} rows)")

# ── Explode skills into separate rows ─────────────
skills_df = df[["job_id","job_title","experience_level","location","salary_usd","skills"]].copy()
skills_df["skills"] = skills_df["skills"].str.split(", ")
skills_df = skills_df.explode("skills")
skills_df["skills"] = skills_df["skills"].str.strip()
skills_df.rename(columns={"skills":"skill"}, inplace=True)
skills_df.to_csv("/home/claude/skills_exploded.csv", index=False)
print(f"[8] Saved: skills_exploded.csv ({len(skills_df):,} rows)")

# ── Summary stats ─────────────────────────────────
print("\n" + "=" * 50)
print("  DATASET SUMMARY")
print("=" * 50)
print(f"  Total jobs      : {len(df):,}")
print(f"  Avg salary (USD): ${df['salary_usd'].mean():,.0f}")
print(f"  Median salary   : ${df['salary_usd'].median():,.0f}")
print(f"  Companies       : {df['company'].nunique()}")
print(f"  Locations       : {df['location'].nunique()}")
print(f"  Date range      : {df['posted_date'].min().date()} → {df['posted_date'].max().date()}")
print(f"\n  Top 5 skills:")
top_skills = skills_df["skill"].value_counts().head(5)
for skill, cnt in top_skills.items():
    print(f"    {skill:<25} {cnt:,} jobs")
print("=" * 50)
