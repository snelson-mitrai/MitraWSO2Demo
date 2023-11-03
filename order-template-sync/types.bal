import ballerina/time;
import ballerinax/rabbitmq;

type TaskMessage record {|
    *rabbitmq:AnydataMessage;
    TaskData content;
|};

type TaskData record {|
    IntegrationTask integrationTask;
    IO_DWH_OrderTemplate updatedTemplate;
|};

type EventData record {|
    int eventID;
    int templateID;
    time:Civil timestamp?;
    string eventType?;
    string status?;
    string origin?;
    string category?;
|};

type IntegrationTask record {|
    int TaskId;
    time:Civil CreatedDatetime;
    time:Civil ModifiedDatetime;
    time:Utc ValidFromUTC;
    time:Utc ValidToUTC;
    string Type;
    string Scope;
|};

type IntegrationLog record {|
    int? LogID = ();
    int TaskID;
    string Status;
    string Scope;
    time:Utc Timestamp;
|};

type IO_DWH_OrderTemplate record {|
    int TemplateID;  
    string Category;
    int CategoryRangeEnd;
    int CategoryRangeStart;
    int CompanyRangeEnd;
    int CompanyRangeStart;
    int DeliveryTime;     
    string Description;
    boolean IncludeBuyingDeals;
    boolean IncludeNegatives;
    boolean IncludeOutOfStocks;
    boolean IncludeUncollectedScripts;  
    string OrderContent;
    int OrderPeriodDays;
    string OrderType;
    int RoundUpAfter;
    time:Date RunDate;  
    string RunFrequency;
    int ShelfPackRound; 
    string Supplier;
    boolean UseDefaultSuppliers;
    int ZFactor;
|};
