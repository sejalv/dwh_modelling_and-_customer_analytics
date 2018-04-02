-- Given Schema:

CREATE TABLE IF NOT EXISTS dwh.user_first_install_fact (
  user_id VARCHAR(36),
  install_id VARCHAR(36),
  device_id  VARCHAR(36),
  installed_at TIMESTAMP,
  DATE_sk INT,
  client_sk INT,                      
  channel_sk INT,                     
  country_code VARCHAR(7),
  network_name VARCHAR(256),
  campaign_name VARCHAR(256),
  adGROUP_name VARCHAR(256),
  creative_name VARCHAR(256),
  campaign_id VARCHAR(256),
  adGROUP_id VARCHAR(256),
  creative_id VARCHAR(256),
  ip_address VARCHAR(39)
);

CREATE TABLE client_dim (
  client_sk   INTEGER,
  os_name     VARCHAR(256),
  app_name    VARCHAR(256),
  app_version VARCHAR(256),
  device_name VARCHAR(256),
  PRIMARY KEY (client_sk)
);

CREATE TABLE IF NOT EXISTS dwh.channel_dim (
  channel_sk INT,
  channel_name TEXT,
  channel_GROUP TEXT,
  channel_label TEXT,
  PRIMARY KEY (channel_sk)
);



-- Solutions:

/* Question 1
Write a query, using Redshift ANSI SQL, to find which user_id has duplicated installs (more than one install) for yesterday.
*/

WITH dup_inst as
(
  SELECT 
      user_id, count(*) AS cnt
  	FROM user_first_install_fact 
  	WHERE DATE(installed_at) = DATE(current_timestamp)-1
  	GROUP BY 1
  	HAVING count(*) > 1
)
SELECT user_id
  FROM dup_inst;


/*
Question 2
Write a query, using Redshift ANSI SQL, to know which are the top 5 channels WITH the most installs coming in from Android.
*/

WITH all_inst_andr AS
(
SELECT 
    ufif.channel_sk
    , (CASE WHEN cl.os_name = 'Android' THEN 1 ELSE 0 END) AS if_android
  FROM user_first_install_fact ufif
  LEFT JOIN client_dim cl 
    ON ufif.client_sk = cl.client_sk 
)
SELECT 
    ch.channel_name AS Channel
    , COALESCE(SUM(all_inst_andr.if_android),0) AS android_installs
    , COUNT(all_inst_andr.channel_sk) AS total_installs
  FROM channel_dim ch
  LEFT JOIN all_inst_andr ON ch.channel_sk = all_inst_andr.channel_sk
  GROUP BY ch.channel_sk
  ORDER BY android_installs DESC, total_installs DESC
  LIMIT 5;

/*
OUTPUT:

| Channel | android_installs | total_installs |
|---------|------------------|----------------|
|       1 |                2 |              2 |
|       3 |                1 |              2 |
|       5 |                0 |              0 |

*/