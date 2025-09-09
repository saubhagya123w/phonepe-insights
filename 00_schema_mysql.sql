-- Create DB
CREATE DATABASE IF NOT EXISTS phonepe_pulse CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE phonepe_pulse;
create user root;

-- Common reference
CREATE TABLE IF NOT EXISTS dim_time (
  time_id INT AUTO_INCREMENT PRIMARY KEY,
  year INT NOT NULL,
  quarter TINYINT NOT NULL,
  UNIQUE KEY uq_time (year, quarter)
);
select * from dim_time;
CREATE TABLE IF NOT EXISTS dim_geo_state (
  state_id INT AUTO_INCREMENT PRIMARY KEY,
  state_name VARCHAR(80) NOT NULL UNIQUE
);
select * from dim_geo_state;
CREATE TABLE IF NOT EXISTS dim_geo_district (
  district_id INT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  district_name VARCHAR(120) NOT NULL,
  UNIQUE KEY uq_state_district (state_id, district_name),
  FOREIGN KEY (state_id) REFERENCES dim_geo_state(state_id)
);

-- 1) Aggregated Transactions (by category)
CREATE TABLE IF NOT EXISTS f_agg_txn (
  txn_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  time_id INT NOT NULL,
  txn_type VARCHAR(50) NOT NULL,         -- e.g., "Peer-to-peer payments", "Recharge"
  txn_count BIGINT NOT NULL,
  txn_amount DECIMAL(18,2) NOT NULL,
  FOREIGN KEY (state_id) REFERENCES dim_geo_state(state_id),
  FOREIGN KEY (time_id) REFERENCES dim_time(time_id),
  KEY k_state_time (state_id, time_id),
  KEY k_type (txn_type)
);
select * from dim_geo_state;
-- 2) Map Transactions (district granularity)
CREATE TABLE IF NOT EXISTS f_map_txn_district (
  map_txn_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  district_id INT NOT NULL,
  time_id INT NOT NULL,
  txn_count BIGINT NOT NULL,
  txn_amount DECIMAL(18,2) NOT NULL,
  FOREIGN KEY (state_id) REFERENCES dim_geo_state(state_id),
  FOREIGN KEY (district_id) REFERENCES dim_geo_district(district_id),
  FOREIGN KEY (time_id) REFERENCES dim_time(time_id),
  KEY k_state_dist_time (state_id, district_id, time_id)
);

-- 3) Top Transactions (state’s top districts/pincodes/entities)
CREATE TABLE IF NOT EXISTS f_top_txn (
  top_txn_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  time_id INT NOT NULL,
  entity_type ENUM('district','pincode','merchant','other') NOT NULL,
  entity_name VARCHAR(120) NOT NULL,
  txn_count BIGINT NOT NULL,
  txn_amount DECIMAL(18,2) NOT NULL,
  FOREIGN KEY (state_id) REFERENCES dim_geo_state(state_id),
  FOREIGN KEY (time_id) REFERENCES dim_time(time_id),
  KEY k_entity (entity_type, entity_name)
);

-- 4) Aggregated Users (device/brand breakdown etc.)
CREATE TABLE IF NOT EXISTS f_agg_user_device (
  user_dev_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  time_id INT NOT NULL,
  brand VARCHAR(80) NOT NULL,
  user_count BIGINT NOT NULL,
  pct DECIMAL(7,4) NULL,                 -- percentage if available
  FOREIGN KEY (state_id) REFERENCES dim_geo_state(state_id),
  FOREIGN KEY (time_id) REFERENCES dim_time(time_id),
  KEY k_brand (brand)
);

-- 5) Map Users (district registered users/app opens)
CREATE TABLE IF NOT EXISTS f_map_user_district (
  map_user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  district_id INT NOT NULL,
  time_id INT NOT NULL,
  registered_users BIGINT NOT NULL,
  app_opens BIGINT NULL,
  FOREIGN KEY (state_id) REFERENCES dim_geo_state(state_id),
  FOREIGN KEY (district_id) REFERENCES dim_geo_district(district_id),
  FOREIGN KEY (time_id) REFERENCES dim_time(time_id)
);

-- 6) Top Users (pincode top registered users)
CREATE TABLE IF NOT EXISTS f_top_user (
  top_user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  time_id INT NOT NULL,
  pincode VARCHAR(10) NOT NULL,
  registered_users BIGINT NOT NULL,
  FOREIGN KEY (state_id) REFERENCES dim_geo_state(state_id),
  FOREIGN KEY (time_id) REFERENCES dim_time(time_id),
  KEY k_pin (pincode)
);

-- 7) Insurance (aggregated + map + top if present in repo)
CREATE TABLE IF NOT EXISTS f_agg_insurance (
  ins_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  time_id INT NOT NULL,
  ins_type VARCHAR(80) NOT NULL,         -- e.g., premium collection category
  ins_count BIGINT NOT NULL,
  ins_amount DECIMAL(18,2) NOT NULL,
  FOREIGN KEY (state_id) REFERENCES dim_geo_state(state_id),
  FOREIGN KEY (time_id) REFERENCES dim_time(time_id)
);

CREATE TABLE IF NOT EXISTS f_map_insurance_district (
  map_ins_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  district_id INT NOT NULL,
  time_id INT NOT NULL,
  ins_count BIGINT NOT NULL,
  ins_amount DECIMAL(18,2) NOT NULL,
  FOREIGN KEY (state_id) REFERENCES dim_geo_state(state_id),
  FOREIGN KEY (district_id) REFERENCES dim_geo_district(district_id),
  FOREIGN KEY (time_id) REFERENCES dim_time(time_id)
);

CREATE TABLE IF NOT EXISTS f_top_insurance (
  top_ins_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  state_id INT NOT NULL,
  time_id INT NOT NULL,
  entity_type ENUM('district','pincode','category','other') NOT NULL,
  entity_name VARCHAR(120) NOT NULL,
  ins_count BIGINT NOT NULL,
  ins_amount DECIMAL(18,2) NOT NULL,
  FOREIGN KEY (state_id) REFERENCES dim_geo_state(state_id),
  FOREIGN KEY (time_id) REFERENCES dim_time(time_id)
);
SELECT * FROM f_agg_txn LIMIT 10;
SELECT * FROM f_top_insurance LIMIT 10;