CREATE OR REPLACE STREAM "ALARM_STREAM" (order_count INTEGER);

-- when you select rows, you insert results in another in-application stream
-- use pumps to write to in-application streams
CREATE OR REPLACE PUMP "STREAM_PUMP" AS 
	INSERT INTO "ALARM_STREAM"
		-- return order count
		SELECT STREAM order_count
		FROM (
			-- count orders over a 10 second sliding window
			SELECT STREAM COUNT(*) OVER TEN_SECOND_SLIDING_WINDOW AS order_count
			FROM "SOURCE_SQL_STREAM_001"
			WINDOW TEN_SECOND_SLIDING_WINDOW AS (RANGE INTERVAL '10' SECOND PRECEDING)
		)
		-- when there are 10+ orders over the course of 10 second window
		WHERE order_count >= 10;

CREATE OR REPLACE STREAM TRIGGER_COUNT_STREAM(
	order_count INTEGER,
	trigger_count INTEGER);
	
CREATE OR REPLACE PUMP trigger_count_pump AS INSERT INTO TRIGGER_COUNT_STREAM
SELECT STREAM order_count, trigger_count
FROM (
	SELECT STREAM order_count, COUNT(*) OVER W1 as trigger_count
	FROM "ALARM_STREAM"
	WINDOW W1 AS (RANGE INTERVAL '1' MINUTE PRECEDING)
)
WHERE trigger_count >= 1;
