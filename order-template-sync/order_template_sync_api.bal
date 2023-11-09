import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/rabbitmq;

final mysql:Client integrationDbClient = check new (
    host = dbHost, user = dbUser, password = dbPassword, port = 3306, database = integrationDb
);

final mysql:Client IO_DWHDbClient = check new (
    host = dbHost, user = dbUser, password = dbPassword, port = 3306, database = iodwhDb
);

service / on new http:Listener(8080) {
    private final rabbitmq:Client 'rabbitmq;

    function init() returns error? {
        self.'rabbitmq = check new (rabbitMqHost, rabbitMqPort, {username: rabbitMqUser, password: rabbitMqPassword, virtualHost: rabbitMqVhost});
        check self.'rabbitmq->queueDeclare(queueName);
        log:printInfo("Listening on order template sync tasks.");
    }

    isolated resource function post .(@http:Payload EventData event) returns string|error {
        log:printInfo("order template sync event received.", event = event);
        IntegrationTask orderTemplateSyncTask = check lookUpIntegrationTaskTable(event);
        log:printInfo("order template sync task loaded from database", orderTemplateSyncTask = orderTemplateSyncTask);

        check updateIntegrationLogTable(orderTemplateSyncTask.TaskId, "In-Progress", orderTemplateSyncTask.Scope);

        IO_DWH_OrderTemplate updatedTemplate = check lookUpUpdatedOrderTemplate(event.templateID);

        log:printInfo("found the order template", orderTemplate = updatedTemplate);

        TaskMessage taskMessage = {
            content: {integrationTask: orderTemplateSyncTask, updatedTemplate: updatedTemplate},
            routingKey: queueName
        };
        error? queueResult = self.'rabbitmq->publishMessage(taskMessage);
        if queueResult is error {
            log:printError(string `Error occurred while queuing the task: ${queueResult.message()}`, queueResult);
            return queueResult;
        }

        return "success";
    }
}

isolated function lookUpIntegrationTaskTable(EventData event) returns IntegrationTask|error {
    return check integrationDbClient->queryRow(`SELECT * FROM Task WHERE type = ${taskType}`);
}

isolated function updateIntegrationLogTable(int taskID, string status, string scope) returns error? {
    sql:ExecutionResult result = check integrationDbClient->execute(`
        INSERT INTO Log (TaskID, Status, Scope, Timestamp)
        VALUES (${taskID}, ${status}, ${scope}, ${time:utcNow()})
    `);
    int|string? lastInsertId = result.lastInsertId;
    if lastInsertId is int {
        log:printInfo("Logged status " + status + " for the task " + taskID.toString() + ".");
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

const taskType = "Order Template Sync";
configurable string queueName = "q_order_template_sync";

configurable int rabbitMqPort = ?;
configurable string rabbitMqHost = ?;
configurable string rabbitMqUser = ?;
configurable string rabbitMqPassword = ?;
configurable string rabbitMqVhost = ?;

configurable string dbUser = ?;
configurable string dbPassword = ?;
configurable string dbHost = ?;
configurable string integrationDb = ?;
configurable string iodwhDb = ?;

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
