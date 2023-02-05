--Create table and copy in data

CREATE TABLE listings (
	
	id VARCHAR(30) PRIMARY KEY,
	name VARCHAR(300),	
	host_id	INT,
	host_since DATE,
	host_response_time VARCHAR(30),
	host_response_rate	VARCHAR(4),
	host_acceptance_rate VARCHAR(4),
	host_is_superhost BOOLEAN,
	host_has_profile_pic BOOLEAN,
	host_identity_verified BOOLEAN, 
	neighborhood_cleansed VARCHAR(50),
	neighborhood_group_cleansed	VARCHAR(50),
	latitude DECIMAL(8,5),
	longitude DECIMAL(8,5),
	property_type VARCHAR(50),
	room_type VARCHAR(50),
	accommodates SMALLINT,
	bathrooms_text VARCHAR(50),
	bedrooms SMALLINT,
	beds SMALLINT,
	amenities VARCHAR(1000),
	price VARCHAR(15),
	minimum_nights SMALLINT,
	maximum_nights SMALLINT,
	availability_30 SMALLINT,
	availability_60 SMALLINT,
	availability_90 SMALLINT,
	availability_365 SMALLINT,
	number_of_reviews SMALLINT,
	number_of_reviews_ltm SMALLINT,
	number_of_reviews_l30d SMALLINT,
	first_review DATE,
	last_review	DATE,
	review_scores_rating DECIMAL(5,2),
	review_scores_accuracy DECIMAL(5,2),
	review_scores_cleanliness DECIMAL(5,2),
	review_scores_checkin DECIMAL(5,2),	
	review_scores_communication DECIMAL(5,2),
	review_scores_location DECIMAL(5,2),
	review_scores_value DECIMAL(5,2),
	instant_bookable BOOLEAN

);

COPY listings 
FROM 'C:\Users\Owner\Downloads\Job Portfolio\NYC Airbnb\listings.csv 2\listings.csv'
DELIMITER ','
CSV HEADER;

--Columns needs to be changed to fit the data

ALTER TABLE listings
ALTER COLUMN amenities TYPE VARCHAR(2000);

ALTER TABLE listings
ALTER COLUMN maximum_nights TYPE BIGINT;

--Checking data

SELECT * FROM listings
LIMIT 5;

--Changing N/A to null and changing type to remove % and changing to decimal type in two columns (so we can do operations)

UPDATE listings SET host_response_rate = NULL 
WHERE host_response_rate = 'N/A';

UPDATE listings SET host_acceptance_rate = NULL 
WHERE host_acceptance_rate = 'N/A';

UPDATE listings SET host_response_rate = REPLACE(host_response_rate,'%','');
UPDATE listings SET host_acceptance_rate = REPLACE(host_acceptance_rate,'%','');

ALTER TABLE listings
ALTER COLUMN host_response_rate TYPE DECIMAL(5,2) USING(host_response_rate::numeric(5,2));

ALTER TABLE listings
ALTER COLUMN host_acceptance_rate TYPE DECIMAL(5,2) USING(host_acceptance_rate::numeric(5,2));

--Doing a similar thing as above but this time with the price column

UPDATE listings SET price = REPLACE(price,'$','');
UPDATE listings SET price = REPLACE(price,',','');

ALTER TABLE listings
ALTER COLUMN price TYPE DECIMAL(8,2) USING(price::numeric(8,2));

--Updating bedrooms column to change null values to 0 where the rooms accommodates people

UPDATE listings SET bedrooms = 0
WHERE accommodates IS NOT NULL AND bedrooms IS NULL;

--Checking if the above worked correctly

SELECT * FROM listings
LIMIT 20;

--Time to explore: checking our most populated neighborhoods and their average prices

SELECT neighborhood_cleansed, neighborhood_group_cleansed, COUNT(*), AVG(price)
FROM listings
GROUP BY neighborhood_group_cleansed, neighborhood_cleansed
ORDER BY --count
avg DESC;

--Noticing some extremely high values in two neighborhoods, going to check them out

SELECT id, price FROM listings
WHERE neighborhood_cleansed = 'Coney Island';

SELECT * FROM listings 
WHERE id = '15604499';

--Error with the above id (says price is $75k per night for private room and other rows misformatted), going to delete it

DELETE FROM listings
WHERE id = '15604499';

--Checking the other neighborhood, doing a similar thing

SELECT id, price FROM listings
WHERE neighborhood_cleansed = 'West Brighton';

SELECT * FROM listings 
WHERE id = '52801188';

SELECT * FROM listings 
WHERE id = '16289102';

DELETE FROM listings
WHERE id = '52801188';

DELETE FROM listings
WHERE id = '16289102';

--Looking at our neighborhoods again

SELECT neighborhood_cleansed, neighborhood_group_cleansed, COUNT(*), AVG(price)
FROM listings
GROUP BY neighborhood_group_cleansed, neighborhood_cleansed
ORDER BY --count
avg DESC;

--Checking to see if we have any neighborhoods that have the same name but are in different boroughs

SELECT DISTINCT(neighborhood_cleansed) FROM listings;

--We don't so we don't have to keep grouping by both categories

--Finding our 10 most popular neighborhoods

SELECT neighborhood_cleansed, COUNT(*), AVG(price)
FROM listings
GROUP BY neighborhood_cleansed
ORDER BY count DESC
LIMIT 10;

--Noticing they are all Brooklyn/Manhattan, lets see a breakdown by borough

SELECT neighborhood_group_cleansed, COUNT(*), AVG(price)
FROM listings
GROUP BY neighborhood_group_cleansed
ORDER BY count DESC;

--Finding how many are in BK/Manhattan vs other 3 boroughs

SELECT neighborhood_group_cleansed, COUNT(*) * 100/ SUM(COUNT(*)) OVER() as percent_of_total
FROM listings
GROUP BY neighborhood_group_cleansed
ORDER BY percent_of_total DESC;

--BK/Manhattan combine for 80% of all listings

--Let's look at the average review across our data, and also our distirbution

SELECT AVG(review_scores_rating) FROM listings;

SELECT MAX(cume_dist) FROM (
SELECT review_scores_rating, 
CUME_DIST() OVER(ORDER BY review_scores_rating) FROM listings) as cume
WHERE review_scores_rating = 4;

SELECT (cume_dist) FROM (
SELECT review_scores_rating, 
CUME_DIST() OVER(ORDER BY review_scores_rating) FROM listings) as cume
WHERE review_scores_rating = 4.8;


--Average score is about 4.62, the probability that the score is less than a 4 is about 7%,
--and the probability it is less than 4.8 is 40%

SELECT MAX(review_scores_rating) FROM 
	(SELECT id, review_scores_rating, NTILE(4) OVER (ORDER BY review_scores_rating) as quartile
	FROM listings) as q
WHERE quartile = 1 OR quartile = 3
GROUP BY quartile;

--Our middle 50% of values lie between 4.67 and 5, that means our top 25% are all 5 stars

--Same thing as above but with price

SELECT MAX(price) FROM 
	(SELECT id, price, NTILE(4) OVER (ORDER BY price) as quartile
	FROM listings) as q
WHERE quartile = 1 OR quartile = 3
GROUP BY quartile;

--Middle 50% of of values for all lie between 75 and 200

--Does host response rate factor into your overall review score?

SELECT 
(SELECT AVG(review_scores_rating) FROM listings
WHERE host_response_rate = 100)
-
(SELECT AVG(review_scores_rating) FROM listings
WHERE host_response_rate != 100);

--Affects score by about .17 on average for those that respond to all messages

--How does acceptance rate affect review score?

SELECT 
(SELECT AVG(review_scores_rating) FROM listings
WHERE host_acceptance_rate >= 60)
-
(SELECT AVG(review_scores_rating) FROM listings
WHERE host_acceptance_rate < 60);

--Doesn't seem to have a correlation

--What is the average price by each borough?

SELECT neighborhood_group_cleansed, AVG(price) FROM listings
GROUP BY neighborhood_group_cleansed
ORDER BY avg DESC;

--Interesting to see that aside from Manhattan, different boroughs don't carry a premium
--Let's look at the IQR for Manhattan

SELECT MAX(price) FROM 
	(SELECT id, price, NTILE(4) OVER (ORDER BY price) as quartile
	FROM listings
	WHERE neighborhood_group_cleansed = 'Manhattan'
	) as q
WHERE quartile = 1 OR quartile = 3
GROUP BY quartile;

--Middle 50% of of values for lie between 100 and 270

--What neighborhoods have been getting the best reviews in 2022? Want to see only neighborhoods that have
--enough properties rated in 2022

SELECT neighborhood_cleansed, COUNT(*), AVG(review_scores_rating) FROM listings
WHERE last_review > '12-31-2021'
GROUP BY neighborhood_cleansed
HAVING COUNT(*) > 25
ORDER BY avg DESC
LIMIT 10;

--Are properties with a certain number of bedrooms likely to be reviewed higher?

SELECT DISTINCT(property_type) FROM listings;

SELECT bedrooms, COUNT(*), AVG(review_scores_rating) FROM listings
WHERE property_type LIKE 'Entire%'
GROUP BY bedrooms
ORDER BY avg DESC;

--Doesn't seem to be correlated

--What about the price difference? Looking at Manhattan

SELECT bedrooms, COUNT(*), AVG(price) FROM listings
WHERE neighborhood_group_cleansed = 'Manhattan' AND property_type LIKE 'Entire%'
GROUP BY bedrooms
ORDER BY avg DESC;

--About $30 more to go from studio to 1br, $120 more to go from 1br to 2br, $175 to go to 3br

--Do private/shared/entire properties get reviewed differently?

SELECT --COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE property_type LIKE 'Shared%'
ORDER BY avg DESC;

SELECT --COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE property_type LIKE 'Private%'
ORDER BY avg DESC;

SELECT --COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE property_type LIKE 'Entire%'
ORDER BY avg DESC;

--Shared vs private difference is about .12, private vs entire difference is about .13

--Now checking how response time affects score

SELECT DISTINCT(host_response_time)
FROM listings;

SELECT --COUNT(*), 
AVG(review_scores_rating) FROM listings
--WHERE host_response_time LIKE 'within%'
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE host_response_time = 'within a few hours'
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE host_response_time = 'within an hour'
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE host_response_time = 'within a day'
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE host_response_time = 'a few days or more'
ORDER BY avg DESC;

--Get about .1 higher score when response is within a day compared to overall average
--Slight difference (about .03) when responding within an hour compared to within a day or a few hours
--About .16 difference responding within an hour vs a few days

--If a host has a certain min/max nights they need for a stay, does that affect review score?

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE minimum_nights >= 30
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE minimum_nights < 30
ORDER BY avg DESC;

--.22 higher scores on less than month long stays

--What affect do having certain amenities have?

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE amenities --NOT 
LIKE '%AC%'
ORDER BY avg DESC;

--.19 higher score for units with AC

--Being a superhost/idenitity verified/profile pic, and its affect on score/price

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE host_is_superhost IS --NOT 
TRUE
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(price) FROM listings
WHERE host_is_superhost IS NOT 
TRUE
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE host_has_profile_pic IS NOT 
TRUE
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE host_identity_verified IS --NOT 
TRUE
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(price) FROM listings
WHERE host_identity_verified IS --NOT 
TRUE
ORDER BY avg DESC;


--Being a superhost gives about .31 review and $10 price increase than those not, only 174 out of 30k properties 
--don't have a profile pic so not enough to say, being identity verified gives ou about .1 higher score on average
--and not a minimal price increase (about $7)

--Do hosts that have been on the site longer command a higher premium or get better reviews?

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE host_since < '01-01-2013'
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(price) FROM listings
WHERE host_since < '01-01-2013'
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE host_since > '12-31-2017'
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(price) FROM listings
WHERE host_since > '12-31-2017'
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(review_scores_rating) FROM listings
WHERE host_since > '12-31-2019'
ORDER BY avg DESC;

SELECT COUNT(*), 
AVG(price) FROM listings
WHERE host_since > '12-31-2019'
ORDER BY avg DESC;

--Hosts that joined the platform on average receive about .12-.13 premium than those that joined after 2018 or 2020
--Prices are $30 cheaper for older hosts compared to those that joined in 2018 or later, $40 cheaper than 2020 hosts

--What about number of reviews for a listing? 

SELECT AVG(number_of_reviews) FROM listings;

SELECT AVG(review_scores_rating) FROM listings
WHERE number_of_reviews > 33
ORDER BY avg DESC;

SELECT AVG(review_scores_rating) FROM listings
WHERE number_of_reviews < 33
ORDER BY avg DESC;

--Units with more reviews than average (33) get on average .2 higher reviews

--Let's look at the hosts who have the most listings

SELECT host_id, COUNT(*), avg(review_scores_rating), AVG(price) FROM listings
GROUP BY host_id
ORDER BY count DESC
LIMIT 10;

--Interesting to note the wide variety in scores here - some around the average, some around 4.9, some around 4
--Same with price - Some range upwards of $400 to a bottom of around $30

--Let's dive into these hosts more

SELECT host_id, neighborhood_group_cleansed,
COUNT(*), AVG(price), AVG(review_scores_rating) FROM listings
WHERE host_id IN('107434423', '158969505', '3223938', '19303369', '22541573', '204704622',
				 '51501835', '200239515', '61391963', '371972456')
GROUP BY host_id, neighborhood_group_cleansed
ORDER BY count DESC;

SELECT host_id, --neighborhood_group_cleansed,
neighborhood_cleansed,
COUNT(*), AVG(price), AVG(review_scores_rating) FROM listings
WHERE host_id = '3223938'
GROUP BY host_id, --neighborhood_group_cleansed
neighborhood_cleansed
ORDER BY count DESC;

--Incredible reviews for '3223938' in multiple boroughs at an extremely cheap price

SELECT host_id, --neighborhood_group_cleansed,
neighborhood_cleansed,
COUNT(*), AVG(price), AVG(review_scores_rating) FROM listings
WHERE host_id = '107434423'
GROUP BY host_id, --neighborhood_group_cleansed
neighborhood_cleansed
ORDER BY count DESC;

--Basically stays in Manhattan but goes all over, gets average reviews but commands a very high price

SELECT host_id, --neighborhood_group_cleansed,
neighborhood_cleansed,
COUNT(*), AVG(price), AVG(review_scores_rating) FROM listings
WHERE host_id = '158969505'
GROUP BY host_id, --neighborhood_group_cleansed
neighborhood_cleansed
ORDER BY count DESC;

--Similar to above but less units and doesn't command quite the price - stays in LES mostly and NoLita
--Is this because of neighborhood, property type, something else?

SELECT property_type, COUNT(*) FROM listings
WHERE host_id = '158969505' OR host_id = '107434423'
GROUP BY property_type
ORDER BY count DESC;

SELECT host_id, bedrooms, COUNT(*) FROM listings
WHERE host_id = '158969505' OR host_id = '107434423'
GROUP BY host_id,bedrooms
ORDER BY count DESC;

--Basically all entire units, similar distribution of bedrooms, mostly affected by neighborhood

SELECT host_id, --neighborhood_group_cleansed,
neighborhood_cleansed,
COUNT(*), AVG(price), AVG(review_scores_rating) FROM listings
WHERE host_id = '204704622'
GROUP BY host_id, --neighborhood_group_cleansed
neighborhood_cleansed
ORDER BY count DESC;

--Seems this host gets extremely bad reviews (operated in Queens), is this a borough/neighborhood problem?

SELECT neighborhood_group_cleansed, AVG(review_scores_rating) FROM listings
GROUP BY neighborhood_group_cleansed

SELECT neighborhood_cleansed, AVG(review_scores_rating) FROM listings
WHERE neighborhood_group_cleansed = 'Queens'
GROUP BY neighborhood_cleansed

--No for the most part it seems this host is just operating poorly, pricing reflects that
--Majority of the other owners are operating as expect in terms of price


--Now we are done exploring the data, let's make some visualiztions to show what we learned!












