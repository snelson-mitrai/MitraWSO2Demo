import ballerina/sql;
import ballerina/time;
import ballerina/log;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

final mysql:Client integrationDbClient = check new(
    host=DB_HOST, user=DB_USER, password=DB_PASSWORD, port=DB_PORT, database="Integration"
);

final mysql:Client IO_DWHDbClient = check new(
    host=DB_HOST, user=DB_USER, password=DB_PASSWORD, port=DB_PORT, database="IO_DWH"
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
