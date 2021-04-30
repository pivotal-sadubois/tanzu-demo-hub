DROP TABLE IF EXISTS tdh_info;

CREATE TABLE tdh_info (
	id          SERIAL PRIMARY KEY,
	url         VARCHAR(255) NOT NULL,
	name        VARCHAR(255) NOT NULL,
	description VARCHAR (255),
	last_update DATE
);

INSERT INTO tdh_info (url, name)
VALUES('https://github.com/pivotal-sadubois/tanzu-demo-hub','Tanzu Demo Hub');
