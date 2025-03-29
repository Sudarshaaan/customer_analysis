use customer_behaviour_analysis


-- Write SQL Queries to Extract Relevant Data
-- This query extracts customer details, products they reviewed, ratings, and actions from the journey.

SELECT 
    c.CustomerID, 
    c.CustomerName, 
    c.Age, 
    g.Country, 
    p.ProductName, 
    cr.Rating, 
    j.Stage, 
    j.Action, 
    j.Duration
FROM 
    customers c
JOIN 
    geography g ON c.GeographyID = g.GeographyID
JOIN 
    customer_journey j ON c.CustomerID = j.CustomerID
JOIN 
    customer_reviews cr ON c.CustomerID = cr.CustomerID
JOIN 
    products p ON p.ProductID = cr.ProductID;
    
    
    -- Window Function: Calculate the average rating for each product over the customer journey
    
    SELECT 
    p.ProductName, 
    cr.Rating, 
    AVG(cr.Rating) OVER (PARTITION BY p.ProductID) AS AvgRating,
    j.Action, 
    j.Duration
FROM 
    customer_reviews cr
JOIN 
    products p ON cr.ProductID = p.ProductID
JOIN 
    customer_journey j ON cr.CustomerID = j.CustomerID;


-- CTEs: Use CTEs to calculate deeper insights such as the total engagement and average rating of a product

WITH ProductRatings AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        AVG(cr.Rating) AS AvgRating
    FROM 
        customer_reviews cr
    JOIN 
        products p ON cr.ProductID = p.ProductID
    GROUP BY 
        p.ProductID, p.ProductName  -- Added p.ProductName here
)
SELECT 
    pr.ProductName, 
    pr.AvgRating, 
    e.ViewsClicksCombined
FROM 
    ProductRatings pr
JOIN 
    engagement_data e ON pr.ProductID = e.ProductID;
    
    
    
-- Subqueries: Find customers who have given the highest rating for a product.

SELECT 
    c.CustomerName, 
    cr.Rating, 
    p.ProductName
FROM 
    customers c
JOIN 
    customer_reviews cr ON c.CustomerID = cr.CustomerID
JOIN 
    products p ON cr.ProductID = p.ProductID
WHERE 
    cr.Rating = (SELECT MAX(Rating) FROM customer_reviews);
    
    
    -- Identify Drop-off Points in the Customer Journey
    
    SELECT 
    j.Stage, 
    COUNT(j.CustomerID) AS DropOffCount
FROM 
    customer_journey j
LEFT JOIN 
    (SELECT CustomerID, MAX(Stage) AS LastStage FROM customer_journey WHERE Stage = 'Purchase' GROUP BY CustomerID) jp
ON 
    j.CustomerID = jp.CustomerID
WHERE 
    jp.LastStage IS NULL
GROUP BY 
    j.Stage
ORDER BY 
    DropOffCount DESC;
    
    
    -- Find Common Actions Leading to Successful Conversions
    
    SELECT 
    j.Action, 
    COUNT(j.CustomerID) AS ActionCount
FROM 
    customer_journey j
JOIN 
    (SELECT CustomerID FROM customer_journey WHERE Stage = 'Purchase' GROUP BY CustomerID) jp
ON 
    j.CustomerID = jp.CustomerID
WHERE 
    j.Stage <> 'Purchase'
GROUP BY 
    j.Action
ORDER BY 
    ActionCount DESC
LIMIT 5;


-- Calculate Average Duration per Stage for Engagement Insights

SELECT 
    j.Stage, 
    AVG(j.Duration) AS AvgDuration
FROM 
    customer_journey j
GROUP BY 
    j.Stage
ORDER BY 
    AvgDuration DESC;


-- Identify Highest-Rated and Lowest-Rated Products

SELECT 
    p.ProductName, 
    AVG(cr.Rating) AS AvgRating
FROM 
    customer_reviews cr
JOIN 
    products p ON cr.ProductID = p.ProductID
GROUP BY 
    p.ProductID, p.ProductName
ORDER BY 
    AvgRating DESC
LIMIT 5; -- For highest-rated

SELECT 
    p.ProductName, 
    AVG(cr.Rating) AS AvgRating
FROM 
    customer_reviews cr
JOIN 
    products p ON cr.ProductID = p.ProductID
GROUP BY 
    p.ProductID, p.ProductName
ORDER BY 
    AvgRating ASC
LIMIT 5; -- For lowest-rated


-- Calculate Customer Retention Rate

SELECT 
    (COUNT(DISTINCT c.CustomerID) - COUNT(DISTINCT CASE WHEN j.Stage = 'First-time' THEN c.CustomerID END)) / COUNT(DISTINCT c.CustomerID) AS RetentionRate
FROM 
    customers c
JOIN 
    customer_journey j ON c.CustomerID = j.CustomerID
WHERE 
    j.Stage IN ('First-time', 'Repeat')


-- Compare Repeat vs. First-Time Buyers

SELECT 
    j.Stage,
    COUNT(DISTINCT j.CustomerID) AS NumberOfCustomers
FROM 
    customer_journey j
GROUP BY 
    j.Stage
    
    
-- Best-Performing Products per Region

WITH ProductRatingsByRegion AS (
    SELECT 
        g.Country, 
        g.City, 
        p.ProductName, 
        AVG(cr.Rating) AS AvgRating, 
        COUNT(cr.ReviewID) AS NumberOfReviews
    FROM 
        customers c
    JOIN 
        geography g ON c.GeographyID = g.GeographyID
    JOIN 
        customer_reviews cr ON c.CustomerID = cr.CustomerID
    JOIN 
        products p ON cr.ProductID = p.ProductID
    GROUP BY 
        g.Country, g.City, p.ProductID, p.ProductName
)
SELECT 
    Country, 
    City, 
    ProductName, 
    AvgRating, 
    NumberOfReviews
FROM 
    ProductRatingsByRegion
ORDER BY 
    AvgRating DESC


-- Identify Best and Worst Performing Products Based on Reviews

WITH ProductPerformance AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        COUNT(cr.ReviewID) AS TotalReviews,
        AVG(cr.Rating) AS AvgRating
    FROM products p
    LEFT JOIN customer_reviews cr ON p.ProductID = cr.ProductID
    GROUP BY p.ProductID, p.ProductName
)
SELECT 
    ProductName, 
    AvgRating, 
    TotalReviews
FROM ProductPerformance
ORDER BY AvgRating DESC;


--  Find Most Engaging Product Categories

SELECT 
    p.Category,
    SUM(e.ViewsClicksCombined) AS TotalEngagement
FROM products p
JOIN engagement_data e ON p.ProductID = e.ProductID
GROUP BY p.Category
ORDER BY TotalEngagement DESC;


--  Identify Repeat vs. First-Time Buyers

SELECT 
    c.CustomerID,
    COUNT(DISTINCT j.ProductID) AS TotalProductsBought
FROM customer_journey j
JOIN customers c ON j.CustomerID = c.CustomerID
GROUP BY c.CustomerID
HAVING TotalProductsBought > 1;


