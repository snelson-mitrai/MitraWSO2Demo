import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/rabbitmq;

service / on new http:Listener(8080) {
    private final rabbitmq:Client rabbitmqConnection;

    function init() returns error? {
        rabbitmq:ConnectionConfiguration config = {username: RABBITMQ_USER, password: RABBITMQ_PW, virtualHost: RABBITMQ_VHOST};
        self.rabbitmqConnection = check new (RABBITMQ_HOST, RABBITMQ_PORT, config);
        check self.rabbitmqConnection->queueDeclare(queueName);
        log:printInfo("Listening on order template sync tasks.");
    }

    isolated resource function post .(@http:Payload EventData event) returns error? {
        IntegrationTask orderTemplateSyncTask = check lookUpIntegrationTaskTable(event);
        log:printInfo("Order template sync task received.");

        check updateIntegrationLogTable(orderTemplateSyncTask.TaskId, "In-Progress", orderTemplateSyncTask.Scope);

        IO_DWH_OrderTemplate updatedTemplate = check lookUpUpdatedOrderTemplate(event.templateID);
        TaskMessage taskMessage = {
            content: {integrationTask: orderTemplateSyncTask, updatedTemplate: updatedTemplate},
            routingKey: queueName
        };
        error? queueResult = self.rabbitmqConnection->publishMessage(taskMessage);
        if queueResult is error {
            log:printError(string `Error occurred while queuing the task: ${queueResult.message()}`, queueResult);
            return queueResult;
        }
    }
}

const taskType = "Order Template Sync";
configurable string  queueName = "TaskQueue";

configurable int RABBITMQ_PORT = ?;
configurable string RABBITMQ_HOST = ?;
configurable string RABBITMQ_USER = ?;
configurable string RABBITMQ_PW = ?;
configurable string RABBITMQ_VHOST = ?;

configurable string DB_USER = ?;
configurable string DB_PASSWORD = ?;
configurable string DB_HOST = ?;
int DB_PORT = 3306;
configurable string INTEGRATION_DB = ?;
configurable string IO_DWH_DB = ?;

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

final mysql:Client integrationDbClient = check new (
    host = DB_HOST, user = DB_USER, password = DB_PASSWORD, port = DB_PORT, database = INTEGRATION_DB
);

final mysql:Client IO_DWHDbClient = check new (
    host = DB_HOST, user = DB_USER, password = DB_PASSWORD, port = DB_PORT, database = IO_DWH_DB
);

isolated function lookUpIntegrationTaskTable(EventData event) returns IntegrationTask|error {
    IntegrationTask task = check integrationDbClient->queryRow(
        `SELECT * FROM Task WHERE type = ${taskType}`
    );
    return task;
}

isolated function updateIntegrationLogTable(int taskID, string status, string scope) returns error? {
    IntegrationLog log = {
        TaskID: taskID,
        Status: status,
        Scope: scope,
        Timestamp: time:utcNow()
    };

    sql:ExecutionResult result = check integrationDbClient->execute(`
        INSERT INTO Log (TaskID, Status, Scope, Timestamp)
        VALUES (${log.TaskID}, ${log.Status}, ${log.Scope}, ${log.Timestamp})
    `);
    int|string? lastInsertId = result.lastInsertId;
    if lastInsertId is int {
        log:printInfo("Logged status " + log.Status + " for the task " + log.TaskID.toString() + ".");
    } else {
        return error("Unable to obtain last insert ID for the log.");
    }
}

isolated function lookUpUpdatedOrderTemplate(int templateID) returns IO_DWH_OrderTemplate|error {
    IO_DWH_OrderTemplate updatedTemplate = check IO_DWHDbClient->queryRow(
        `SELECT * FROM OrderTemplate WHERE TemplateID = ${templateID}`
    );
    return updatedTemplate;
}
