
CREATE TABLE Users (
    user_id         integer         NOT NULL,
    cust_id         varchar(255)    NOT NULL,       -- From Stripe
    country_code    char(2)         NOT NULL,
    address_line1   varchar(255),
    address_line2   varchar(255),
    address_city    varchar(100),
    address_state   varchar(100),
    address_zip     integer         NOT NULL,
    CONSTRAINT user_id_pk PRIMARY KEY (user_id)
);

CREATE TABLE client_dim (
  client_sk   INTEGER,
  os_name     VARCHAR(256),
  app_name    VARCHAR(256),
  app_version VARCHAR(256),
  device_name VARCHAR(256),
CONSTRAINT client_sk_pk PRIMARY KEY (client_sk)
);

CREATE TABLE channel_dim (
  channel_sk    INTEGER,
  channel_name  VARCHAR(256),
  channel_group VARCHAR(256),
  channel_label VARCHAR(256),
CONSTRAINT channel_sk_pk PRIMARY KEY (channel_sk)
);

CREATE TABLE user_first_install_fact (
  user_id       VARCHAR(36),
  install_id    VARCHAR(36),
  device_id     VARCHAR(36),
  installed_at  TIMESTAMP,
  date_sk       INTEGER,
  client_sk     INTEGER,                      
  channel_sk    INTEGER,                     
  country_code  VARCHAR(7),
  network_name  VARCHAR(256),
  campaign_name VARCHAR(256),
  adgroup_name  VARCHAR(256),
  creative_name VARCHAR(256),
  campaign_id   VARCHAR(256),
  adgroup_id    VARCHAR(256),
  creative_id   VARCHAR(256),
  ip_address    VARCHAR(39),
  CONSTRAINT client_sk_fk FOREIGN KEY (client_sk) REFERENCES client_dim(client_sk),
  CONSTRAINT channel_sk_fk FOREIGN KEY (channel_sk) REFERENCES channel_dim(channel_sk)
);

CREATE TABLE User_Saved_Payment_Modes (
    uspm_id                 integer         NOT NULL,
    user_id                 integer         NOT NULL,
    payment_encrypted_id    varchar(255)    NOT NULL,     -- eg. Card ID
    payment_type            varchar(35)     NOT NULL,     -- eg. Credit Card / Debit Card / Wallet (ENUMS)

    -- following 5 columns only if payment_type='Card'
    card_num_last_4_digits  integer,                      
    card_type               varchar(35),                  -- eg. VISA (ENUMS)
    card_brand              varchar(35),                  -- eg. VISA (ENUMS)
    card_exp_month          integer,
    card_exp_year           integer,

    fingerprint             varchar(1000),                -- optional, need not be stored. Also CVV check
    CONSTRAINT uspm_pk PRIMARY KEY (uspm_id),
    CONSTRAINT user_id_fk FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Transactions_Fact (
    transaction_id      integer         NOT NULL,
    uspm_id             integer         NOT NULL,
    transaction_type    varchar(35)     NOT NULL,         -- CHARGE / REFUND etc. (ENUMS)
    amount              decimal(19,4)   NOT NULL,         -- using Decimal for general analytics, can also be stored in total_cents (INTEGER), if accuracy is required
    currency            varchar(3)      NOT NULL,
    transaction_ts      timestamp       NOT NULL,
    CONSTRAINT txn_id_pk PRIMARY KEY (transaction_id),
    CONSTRAINT uspm_fk FOREIGN KEY (uspm_id) REFERENCES User_Saved_Payment_Modes(uspm_id)
);