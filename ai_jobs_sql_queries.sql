-- ============================================================
--  AI Job Market Analytics Dashboard
--  SQL Queries File
--  Compatible with: MySQL 8+ / PostgreSQL 13+
-- ============================================================

-- ── TABLE CREATION ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ai_jobs (
    job_id           INT PRIMARY KEY,
    job_title        VARCHAR(100),
    company          VARCHAR(100),
    location         VARCHAR(100),
    experience_level VARCHAR(20),
    work_type        VARCHAR(20),
    salary_usd       INT,
    skills           TEXT,
    year             INT,
    month            INT,
    posted_date      DATE,
    salary_band      VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS job_skills (
    job_id           INT,
    job_title        VARCHAR(100),
    experience_level VARCHAR(20),
    location         VARCHAR(100),
    salary_usd       INT,
    skill            VARCHAR(100)
);

-- ── IMPORT COMMANDS (MySQL) ──────────────────────────────────
-- LOAD DATA INFILE '/path/to/cleaned_ai_jobs.csv'
-- INTO TABLE ai_jobs FIELDS TERMINATED BY ',' IGNORE 1 ROWS;

-- ── ANALYSIS QUERIES ────────────────────────────────────────

-- Q1: KPI Summary
SELECT
    COUNT(*)                          AS total_jobs,
    ROUND(AVG(salary_usd), 0)         AS avg_salary,
    ROUND(MEDIAN(salary_usd), 0)      AS median_salary,  -- PostgreSQL syntax
    COUNT(DISTINCT company)           AS total_companies,
    COUNT(DISTINCT location)          AS total_locations
FROM ai_jobs;

-- Q2: Top 15 hiring locations
SELECT
    location,
    COUNT(*)                       AS job_count,
    ROUND(AVG(salary_usd), 0)     AS avg_salary
FROM ai_jobs
GROUP BY location
ORDER BY job_count DESC
LIMIT 15;

-- Q3: Highest paying roles (min 50 postings to avoid outliers)
SELECT
    job_title,
    COUNT(*)                       AS total_jobs,
    ROUND(AVG(salary_usd), 0)     AS avg_salary,
    MIN(salary_usd)                AS min_salary,
    MAX(salary_usd)                AS max_salary
FROM ai_jobs
GROUP BY job_title
HAVING COUNT(*) >= 50
ORDER BY avg_salary DESC;

-- Q4: Most demanded skills
SELECT
    skill,
    COUNT(*)                       AS job_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM job_skills), 2) AS pct_of_jobs
FROM job_skills
GROUP BY skill
ORDER BY job_count DESC
LIMIT 20;

-- Q5: Salary by experience level
SELECT
    experience_level,
    COUNT(*)                       AS job_count,
    ROUND(AVG(salary_usd), 0)     AS avg_salary,
    MIN(salary_usd)                AS min_salary,
    MAX(salary_usd)                AS max_salary
FROM ai_jobs
GROUP BY experience_level
ORDER BY avg_salary DESC;

-- Q6: Top hiring companies
SELECT
    company,
    COUNT(*)                       AS openings,
    ROUND(AVG(salary_usd), 0)     AS avg_salary,
    COUNT(DISTINCT job_title)      AS roles_hiring_for
FROM ai_jobs
GROUP BY company
ORDER BY openings DESC
LIMIT 20;

-- Q7: Jobs trend by year
SELECT
    year,
    COUNT(*)                       AS total_jobs,
    ROUND(AVG(salary_usd), 0)     AS avg_salary
FROM ai_jobs
GROUP BY year
ORDER BY year;

-- Q8: Remote vs Hybrid vs Onsite breakdown
SELECT
    work_type,
    COUNT(*)                       AS job_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct,
    ROUND(AVG(salary_usd), 0)     AS avg_salary
FROM ai_jobs
GROUP BY work_type
ORDER BY job_count DESC;

-- Q9: Skills demand by experience level (for bubble chart)
SELECT
    js.skill,
    a.experience_level,
    COUNT(*)                       AS count
FROM job_skills js
JOIN ai_jobs a ON js.job_id = a.job_id
WHERE js.skill IN ('Python','SQL','TensorFlow','PyTorch','AWS','Docker','LLM','NLP','MLOps','Power BI')
GROUP BY js.skill, a.experience_level
ORDER BY js.skill, a.experience_level;

-- Q10: Salary distribution bands
SELECT
    salary_band,
    COUNT(*)                       AS job_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM ai_jobs
GROUP BY salary_band
ORDER BY salary_band;

-- ── USEFUL VIEWS ────────────────────────────────────────────

CREATE OR REPLACE VIEW v_top_skills AS
SELECT skill, COUNT(*) AS demand
FROM job_skills
GROUP BY skill
ORDER BY demand DESC
LIMIT 15;

CREATE OR REPLACE VIEW v_salary_by_role AS
SELECT job_title,
       ROUND(AVG(salary_usd),0) AS avg_salary,
       COUNT(*) AS jobs
FROM ai_jobs
GROUP BY job_title
ORDER BY avg_salary DESC;

CREATE OR REPLACE VIEW v_location_summary AS
SELECT location,
       COUNT(*) AS jobs,
       ROUND(AVG(salary_usd),0) AS avg_salary
FROM ai_jobs
GROUP BY location
ORDER BY jobs DESC;

-- ── DAX MEASURES (for Power BI reference) ───────────────────
/*
Total Jobs     = COUNTROWS(ai_jobs)
Avg Salary     = AVERAGE(ai_jobs[salary_usd])
Median Salary  = MEDIAN(ai_jobs[salary_usd])
Senior Jobs %  = DIVIDE(COUNTROWS(FILTER(ai_jobs, ai_jobs[experience_level]="Senior")), COUNTROWS(ai_jobs)) * 100
Remote Jobs %  = DIVIDE(COUNTROWS(FILTER(ai_jobs, ai_jobs[work_type]="Remote")), COUNTROWS(ai_jobs)) * 100
YoY Growth     = DIVIDE([Total Jobs] - CALCULATE([Total Jobs], PREVIOUSYEAR(ai_jobs[posted_date])), CALCULATE([Total Jobs], PREVIOUSYEAR(ai_jobs[posted_date])))
*/
