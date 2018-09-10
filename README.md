# Ballerina Performance

Ballerina Performance is used to continuously test performance against the latest released ballerina distribution. The following scenarios are covered with this ballerina performance testing.

- passthrough.bal
- https_passthrough.bal
- transformation.bal
- https_transformation.bal
- http2_https_passthrough.bal
- websocket.bal

Performance tests will be executed on a deployment of 5 instances with Jmeter Client, Jmeter Server1, Jmeter Server2, Ballerina and Netty Backend.


## About Ballerina

Ballerina makes it easy to write microservices that integrate APIs.

#### Integration Syntax
A compiled, transactional, statically and strongly typed programming language with textual and graphical syntaxes. Ballerina incorporates fundamental concepts of distributed system integration and offers a type safe, concurrent environment to implement microservices.

#### Networked Type System
A type system that embraces network payload variability with primitive, object, union, and tuple types.

#### Concurrency
An execution model composed of lightweight parallel worker units that are non-blocking where no function can lock an executing thread manifesting sequence concurrency.

## Run Performance Tests

The performance test script is designed to include and exclude scenarios. It allows to change all the parameters as follows.

     ./run-performance-test.sh [-u <concurrent_users>] [-b <message_sizes>] [-s <sleep_times>] [-m <heap_sizes>] [-d <test_duration>] [-w <warmup_time>] [-n <jmeter_servers>] [-j <jmeter_server_heap_size>] [-k <jmeter_client_heap_size>] [-i <include_scenario_name>] [-e <include_scenario_name>] [-t] [-p <estimated_processing_time_in_between_tests>] [-h]


## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community. To start contributing, read these [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md) for information on how you should go about contributing to our project.

Check the issue tracker for open issues that interest you. We look forward to receiving your contributions.

## License

Ballerina code is distributed under [Apache license 2.0](https://github.com/ballerina-platform/ballerina-lang/blob/master/LICENSE).

## Useful links

* The ballerina-dev@googlegroups.com mailing list is for discussing code changes to the Ballerina project.
* Chat live with us on our [Slack channel](https://ballerina-platform.slack.com/).
* Technical questions should be posted on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
