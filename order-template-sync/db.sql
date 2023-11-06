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
