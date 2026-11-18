USE LogisticsDB;


-- 1. Shipments delayed by more than two days with carrier names.
SELECT s.ShipmentID, s.CustomerID, s.HubID, c.CarrierName,
       DATEDIFF(DAY, s.ExpectedDeliveryDate, s.ActualDeliveryDate) AS DelayDays
FROM dbo.Shipments s
JOIN dbo.Carriers c ON c.CarrierID = s.CarrierID
WHERE s.ActualDeliveryDate IS NOT NULL
  AND DATEDIFF(DAY, s.ExpectedDeliveryDate, s.ActualDeliveryDate) > 2
ORDER BY DelayDays DESC;

-- 2. Hubs with no outbound shipments.
SELECT h.HubID, h.HubName
FROM dbo.Hubs h
LEFT JOIN dbo.Shipments s ON s.OriginHubID = h.HubID
WHERE s.ShipmentID IS NULL;

-- 3. Employees with their supervisors.
SELECT e.EmployeeID, e.EmployeeName, e.ManagerID,
       m.EmployeeName AS SupervisorName
FROM dbo.Employees e
LEFT JOIN dbo.Employees m ON m.EmployeeID = e.ManagerID;

-- 4. Customers who have shipments through every hub.
SELECT c.CustomerID, c.CustomerName
FROM dbo.Customers c
WHERE NOT EXISTS (
    SELECT h.HubID
    FROM dbo.Hubs h
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.Shipments s
        WHERE s.CustomerID = c.CustomerID
          AND s.OriginHubID = h.HubID
    )
);

-- 5. Carriers whose average delay is above the overall average delay.
SELECT c.CarrierID, c.CarrierName,
       AVG(DATEDIFF(DAY, s.ExpectedDeliveryDate, s.ActualDeliveryDate)) AS AvgCarrierDelay
FROM dbo.Carriers c
JOIN dbo.Shipments s ON s.CarrierID = c.CarrierID
WHERE s.ActualDeliveryDate IS NOT NULL
GROUP BY c.CarrierID, c.CarrierName
HAVING AVG(DATEDIFF(DAY, s.ExpectedDeliveryDate, s.ActualDeliveryDate)) >
       ALL (
           SELECT AVG(DATEDIFF(DAY, x.ExpectedDeliveryDate, x.ActualDeliveryDate))
           FROM dbo.Shipments x
           WHERE x.ActualDeliveryDate IS NOT NULL
       );

-- 6. Shipments with no delivery event.
SELECT s.ShipmentID, s.CustomerID, s.ExpectedDeliveryDate
FROM dbo.Shipments s
LEFT JOIN dbo.DeliveryEvents d ON d.ShipmentID = s.ShipmentID
WHERE d.EventID IS NULL;

-- 7. Customer names for shipments using IN.
SELECT CustomerID, CustomerName
FROM dbo.Customers
WHERE CustomerID IN (SELECT CustomerID FROM dbo.Shipments);

-- 8. Customer names using EXISTS as a join-style alternative.
SELECT c.CustomerID, c.CustomerName
FROM dbo.Customers c
WHERE EXISTS (
    SELECT 1 FROM dbo.Shipments s
    WHERE s.CustomerID = c.CustomerID
);

-- 9. Carriers and hubs with no matching outbound shipment.
SELECT c.CarrierID, c.CarrierName, h.HubID, h.HubName
FROM dbo.Carriers c
FULL JOIN dbo.Hubs h ON EXISTS (
    SELECT 1
    FROM dbo.Shipments s
    WHERE s.CarrierID = c.CarrierID
      AND s.OriginHubID = h.HubID
)
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Shipments s
    WHERE s.CarrierID = c.CarrierID
      AND s.OriginHubID = h.HubID
);

-- 10. Customers served by carriers with an average delay below 1 day.
SELECT DISTINCT c.CustomerID, c.CustomerName
FROM dbo.Customers c
JOIN dbo.Shipments s ON s.CustomerID = c.CustomerID
WHERE s.CarrierID = ANY (
    SELECT x.CarrierID
    FROM dbo.Shipments x
    WHERE x.ActualDeliveryDate IS NOT NULL
    GROUP BY x.CarrierID
    HAVING AVG(DATEDIFF(DAY, x.ExpectedDeliveryDate, x.ActualDeliveryDate)) < 1
);

-- Nested subquery: second-highest shipping cost per hub.
SELECT s.OriginHubID AS HubID, h.HubName, s.ShippingCost
FROM dbo.Shipments s
JOIN dbo.Hubs h ON h.HubID = s.OriginHubID
WHERE s.ShippingCost = (
    SELECT MAX(x.ShippingCost)
    FROM dbo.Shipments x
    WHERE x.OriginHubID = s.OriginHubID
      AND x.ShippingCost < (
          SELECT MAX(y.ShippingCost)
          FROM dbo.Shipments y
          WHERE y.OriginHubID = s.OriginHubID
      )
);
