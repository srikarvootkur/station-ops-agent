CREATE TABLE site (
    site_id SERIAL PRIMARY KEY,
    brand TEXT,
    address TEXT,
    lat NUMERIC,
    lon NUMERIC,
    tz TEXT
);

CREATE TABLE grade (
    grade_id SERIAL PRIMARY KEY,
    site_id INT REFERENCES site(site_id),
    grade TEXT,
    min_margin_cpg NUMERIC,
    min_price NUMERIC,
    max_daily_changes INT
);

CREATE TABLE wholesale_cost (
    id SERIAL PRIMARY KEY,
    site_id INT REFERENCES site(site_id),
    grade TEXT,
    dtw_price NUMERIC,
    fees_cpg NUMERIC,
    observed_at TIMESTAMP DEFAULT now()
);

CREATE TABLE competitor_observation (
    id SERIAL PRIMARY KEY,
    site_id INT REFERENCES site(site_id),
    station_name TEXT,
    distance_mi NUMERIC,
    grade TEXT,
    price NUMERIC,
    observed_at TIMESTAMP DEFAULT now()
);

CREATE TABLE price_proposal (
    id SERIAL PRIMARY KEY,
    site_id INT REFERENCES site(site_id),
    grade TEXT,
    proposed_price NUMERIC,
    rationale_json JSONB,
    status TEXT,
    created_at TIMESTAMP DEFAULT now(),
    applied_at TIMESTAMP
);
