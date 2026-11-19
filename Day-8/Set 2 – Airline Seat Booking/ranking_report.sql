WITH FareRows AS
(
    SELECT FlightId, PassengerId, Fare
    FROM (VALUES
        ('HX101', 'P-01', CONVERT(decimal(10,2), 320.00)),
        ('HX101', 'P-02', CONVERT(decimal(10,2), 275.00)),
        ('HX101', 'P-03', CONVERT(decimal(10,2), 275.00)),
        ('HX101', 'P-04', CONVERT(decimal(10,2), 210.00)),
        ('HX202', 'P-05', CONVERT(decimal(10,2), 410.00)),
        ('HX202', 'P-06', CONVERT(decimal(10,2), 350.00)),
        ('HX202', 'P-07', CONVERT(decimal(10,2), 350.00))
    ) AS sample(FlightId, PassengerId, Fare)
),
RankedFares AS
(
    SELECT
        FlightId,
        PassengerId,
        Fare,
        RANK() OVER (PARTITION BY FlightId ORDER BY Fare DESC) AS FareRank,
        DENSE_RANK() OVER (PARTITION BY FlightId ORDER BY Fare DESC) AS DenseFareRank,
        SUM(Fare) OVER
        (
            PARTITION BY FlightId
            ORDER BY Fare DESC, PassengerId
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS RunningFlightRevenue
    FROM FareRows
)
SELECT FlightId, PassengerId, Fare, FareRank, DenseFareRank, RunningFlightRevenue
FROM RankedFares
ORDER BY FlightId, Fare DESC, PassengerId;

/*
HX101 ranks are 1, 2, 2, 4 while dense ranks are 1, 2, 2, 3.
The deterministic PassengerId tie-breaker gives a stable running-total order.
*/
