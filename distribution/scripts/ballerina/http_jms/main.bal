import ballerina/http;
import ballerinax/java.jms;
import ballerinax/activemq.driver as _;

configurable string epKeyPath = ?;
configurable string epKeyPassword = ?;
configurable string jmsProviderUrl = ?;

const QUEUE_NAME = "order-queue";

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            path: epKeyPath,
            password: epKeyPassword
        }
    }
);

service /httpToJms on securedEP {
    private final jms:MessageProducer orderProducer;

    function init() returns error? {
        jms:Connection connection = check new (
            initialContextFactory = "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
            providerUrl = jmsProviderUrl
        );

        jms:Session session = check connection->createSession();
        self.orderProducer = check session.createProducer({ 
            'type: jms:QUEUE, 
            name: QUEUE_NAME
        });
    }

    resource function post .(map<json> payload) returns http:Accepted|error {
        jms:MapMessage message = {
            content: payload
        };
        check self.orderProducer->send(message);
        return http:ACCEPTED;
    }
}
