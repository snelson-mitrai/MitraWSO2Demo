import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerinax/rabbitmq;

service / on new http:Listener(8080) {
    private final rabbitmq:Client taskQueueClient;

    function init() returns error? {
        rabbitmq:ConnectionConfiguration config = {username: RABBITMQ_USER, password: RABBITMQ_PW, virtualHost: RABBITMQ_VHOST};
        self.taskQueueClient = check new (RABBITMQ_HOST, RABBITMQ_PORT, config);
        check declareQueueAndExchange(self.taskQueueClient);
    }

    isolated resource function post .(@http:Payload EventData event) returns error? {
        do {
            IntegrationTask orderTemplateSyncTask = check lookUpIntegrationTaskTable(event);
            log:printInfo("Order template sync task received.");

            check updateIntegrationLogTable(orderTemplateSyncTask.TaskId, "In-Progress", orderTemplateSyncTask.Scope);

            IO_DWH_OrderTemplate updatedTemplate = check lookUpUpdatedOrderTemplate(event.templateID);
            TaskMessage taskMessage = {
                content: {integrationTask: orderTemplateSyncTask, updatedTemplate: updatedTemplate},
                routingKey: queueName
            };
            check self.taskQueueClient->publishMessage(taskMessage);
        } on fail error err {
            log:printError(string `Error occurred while queuing the task: ${err.message()}`, err);
            return err;
        }
    }
}

function declareQueueAndExchange(rabbitmq:Client taskQueueClient) returns error? {
    check taskQueueClient->exchangeDeclare(dlxName, rabbitmq:DIRECT_EXCHANGE);
    check taskQueueClient->queueDeclare(dlqName, {durable: true, exclusive: false, autoDelete: false});
    check taskQueueClient->queueBind(dlqName, dlxName, "");

    // Set config to send messages to DLQ
    map<json> arguments = {
        "x-message-ttl": 60000,
        "x-expires": 800000,
        "x-max-retries": 3
    };
    check taskQueueClient->queueDeclare(queueName, {arguments});
}

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
