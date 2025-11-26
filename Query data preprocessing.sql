WITH sales_all AS (
    SELECT * FROM [Sales2009-2010]
    UNION ALL
    SELECT * FROM [Sales2010-2011]
),
duplicated AS (
    SELECT 
        Invoice,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        Price,
        Customer_ID,
        Country,
        Order_Details,
        Sales,
        ROW_NUMBER() OVER (
            PARTITION BY Invoice, StockCode, Description, Quantity, 
                         InvoiceDate, Price, Customer_ID, Country, 
                         Order_Details, Sales
            ORDER BY InvoiceDate
        ) AS duplicate_number
    FROM sales_all
),
missing_values AS (
    SELECT 
        Invoice,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        Price,
        Customer_ID,
        Country,
        Order_Details,
        Sales,
        AVG(Quantity) OVER (PARTITION BY Description) AS Avgquantityperprod,
        AVG(Price) OVER (PARTITION BY Description) AS Avgpriceperprod
    FROM duplicated
    WHERE duplicate_number = 1
      AND Invoice IS NOT NULL     -- ? keep only rows where Invoice has a value
      AND StockCode IS NOT NULL   -- ? you can add or remove columns as needed
      AND Description IS NOT NULL
      AND Quantity IS NOT NULL
      AND InvoiceDate IS NOT NULL
      AND Price IS NOT NULL
      AND Customer_ID IS NOT NULL
      AND Country IS NOT NULL
      AND Order_Details IS NOT NULL
      AND Sales IS NOT NULL
)
SELECT 
    Invoice,
    StockCode,
    Description,
    COALESCE(Quantity, Avgquantityperprod) AS Quantity,
    InvoiceDate,
    COALESCE(Price, Avgpriceperprod) AS Price,
    Customer_ID,
    COALESCE(
        Country,
        (SELECT TOP 1 Country 
         FROM duplicated 
         WHERE Country IS NOT NULL 
         GROUP BY Country 
         ORDER BY COUNT(*) DESC)
    ) AS Country,
    Order_Details,
    Sales
FROM missing_values;
