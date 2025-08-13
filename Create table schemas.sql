-- Create table schemas

-- 1. Create a customer_profiles table

-- Drop the table if it already exists, to remove the old primary key constraint
DROP TABLE IF EXISTS customer_profiles ;

-- Recreate the table
CREATE TABLE customer_profiles (
    customer_id VARCHAR(10) NOT NULL PRIMARY KEY,
    mean_amount FLOAT,
    std_amount FLOAT,
    mean_nb_tx_per_day FLOAT,
    network_id VARCHAR(10),
    bin BIGINT,
    lat_customer FLOAT,
    log_customer FLOAT,
    nb_terminals INT
);

-- 2. Create terminal profile table

-- Drop the table if it already exists
DROP TABLE IF EXISTS terminal_profile;

-- Recreate the table
CREATE TABLE terminal_profiles (
    terminal_id VARCHAR(10) NOT NULL PRIMARY KEY,
    lat_terminal FLOAT,
    log_terminal FLOAT,
    mcc INT
);

-- 3. Separate table to handle the 'available_terminals' data
DROP TABLE IF EXISTS customer_terminal_map;

CREATE TABLE customer_terminal_map (
    customer_id VARCHAR(10) NOT NULL,
    terminal_id VARCHAR(10) NOT NULL,
    PRIMARY KEY (customer_id, terminal_id),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id),
    FOREIGN KEY (terminal_id) REFERENCES terminal_profiles(terminal_id)
);

-- 4. Create transactions table
DROP TABLE IF EXISTS transactions;

CREATE TABLE transactions (
    transaction_id VARCHAR(50) NOT NULL PRIMARY KEY,
    post_ts TIMESTAMP,
    customer_id VARCHAR(10) REFERENCES customer_profiles(customer_id),
    bin BIGINT,
    terminal_id VARCHAR(10) REFERENCES terminal_profiles(terminal_id),
    amt FLOAT,
    entry_mode VARCHAR(50),
    fraud INT,
    fraud_scenario INT
);