const taskType = "Order Template Sync";
const queueName = "TaskQueue";
// Define the Dead Letter Exchange (DLX)
const dlxName = "my_exchange_dlx";
// Define the Dead Letter Queue (DLQ)
const dlqName = "my_queue_dlq";

configurable int RABBITMQ_PORT = ?;
configurable string RABBITMQ_HOST = ?;
configurable string RABBITMQ_USER = ?;
configurable string RABBITMQ_PW = ?;
configurable string RABBITMQ_VHOST = ?;

configurable string DB_USER = ?;
configurable string DB_PASSWORD = ?;
configurable string DB_HOST = ?;
configurable int DB_PORT = ?;
