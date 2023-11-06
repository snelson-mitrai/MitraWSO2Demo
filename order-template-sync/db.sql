create database Integration;
create database IO_DWH;

CREATE TABLE Integration.Task (
     TaskID INT AUTO_INCREMENT,
     CreatedDatetime DATETIME,
     ModifiedDatetime DATETIME,
     ValidFromUTC DATETIME,
     ValidToUTC DATETIME,
     Type VARCHAR(200),
     Scope VARCHAR(100),
     PRIMARY KEY (TaskID)
);

CREATE TABLE Integration.Log (
     LogID INT AUTO_INCREMENT,
     TaskID INT,
     Status VARCHAR(200),
     Scope VARCHAR(200),
     Timestamp DATETIME,
     PRIMARY KEY (LogID)
);

CREATE TABLE IO_DWH.OrderTemplate (
    TemplateID INT,
    Category VARCHAR(200),
    CategoryRangeEnd INT,
    CategoryRangeStart INT,
    CompanyRangeEnd INT,
    CompanyRangeStart INT,
    DeliveryTime INT,
    Description VARCHAR(100),
    IncludeBuyingDeals BIT,
    IncludeNegatives BIT,
    IncludeOutOfStocks BIT,
    IncludeUncollectedScripts BIT,
    OrderContent VARCHAR(100),
    OrderPeriodDays INT,
    OrderType VARCHAR(200),
    RoundUpAfter INT,
    RunDate DATE,
    RunFrequency VARCHAR(100),
    ShelfPackRound INT,
    Supplier VARCHAR(200),
    UseDefaultSuppliers BIT,
    ZFactor INT,
    PRIMARY KEY (TemplateID)
);


INSERT INTO IO_DWH.OrderTemplate (TemplateID, Category, CategoryRangeEnd, CategoryRangeStart, CompanyRangeEnd, CompanyRangeStart, DeliveryTime, Description, IncludeBuyingDeals, IncludeNegatives, IncludeOutOfStocks, IncludeUncollectedScripts, OrderContent, OrderPeriodDays, OrderType, RoundUpAfter, RunDate, RunFrequency, ShelfPackRound, Supplier, UseDefaultSuppliers, ZFactor) VALUES (234, 'BRAND', 10, 5, 100, 40, 14, 'The order template that captures Rosuvastin 5 mg water soluable film coated tablets', 1, 1, 1, 0, 'RETAIL', 14, 'NORMAL', 10, '2023-11-02', 'FORTNIGHTY', 10, 'Mylan Australia QLD', 1, 0);
INSERT INTO IO_DWH.OrderTemplate (TemplateID, Category, CategoryRangeEnd, CategoryRangeStart, CompanyRangeEnd, CompanyRangeStart, DeliveryTime, Description, IncludeBuyingDeals, IncludeNegatives, IncludeOutOfStocks, IncludeUncollectedScripts, OrderContent, OrderPeriodDays, OrderType, RoundUpAfter, RunDate, RunFrequency, ShelfPackRound, Supplier, UseDefaultSuppliers, ZFactor) VALUES (345, 'BRAND', 10, 5, 100, 40, 14, 'The order template that captures Rosuvastin 5 mg water soluable film coated tablets', 1, 1, 1, 0, 'RETAIL', 14, 'NORMAL', 10, '2023-11-02', 'FORTNIGHTY', 10, 'Mylan Australia QLD', 1, 0);
INSERT INTO IO_DWH.OrderTemplate (TemplateID, Category, CategoryRangeEnd, CategoryRangeStart, CompanyRangeEnd, CompanyRangeStart, DeliveryTime, Description, IncludeBuyingDeals, IncludeNegatives, IncludeOutOfStocks, IncludeUncollectedScripts, OrderContent, OrderPeriodDays, OrderType, RoundUpAfter, RunDate, RunFrequency, ShelfPackRound, Supplier, UseDefaultSuppliers, ZFactor) VALUES (456, 'BRAND', 10, 5, 100, 40, 14, 'The order template that captures Rosuvastin 5 mg water soluable film coated tablets', 1, 1, 1, 0, 'RETAIL', 14, 'NORMAL', 10, '2023-11-02', 'FORTNIGHTY', 10, 'Mylan Australia QLD', 1, 0);
