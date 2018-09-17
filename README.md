# Ballerina Performance

Ballerina performance artifacts are used to continuously test the performance of Ballerina services.

These performance test scripts make use of Apache JMeter and a simple Netty Backend Service, which can echo back any 
requests and also add a configurable delay to the response.

In order to support a large number of concurrent users, two or more JMeter Servers can be used.

To fully automate the performance tests, an AWS CloudFormation template is used to create a deployment of 5 EC2 
instances for Apache JMeter Client, 2 Apache JMeter Servers, Ballerina and Netty Backend Service.

## About Ballerina

Ballerina makes it easy to write microservices that integrate APIs.

#### Integration Syntax
A compiled, transactional, statically and strongly typed programming language with textual and graphical syntaxes. Ballerina incorporates fundamental concepts of distributed system integration and offers a type safe, concurrent environment to implement microservices.

#### Networked Type System
A type system that embraces network payload variability with primitive, object, union, and tuple types.

#### Concurrency
An execution model composed of lightweight parallel worker units that are non-blocking where no function can lock an executing thread manifesting sequence concurrency.

## Run Performance Tests

You can run Ballerina Performance Tests from the source using the following instructions.

### Prerequisites

* [Maven 3.5.0 or later](https://maven.apache.org/download.cgi)
* [AWS CLI](https://aws.amazon.com/cli/) - Please make sure to [configure the AWS Cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
and set the output format to `text`.

#### Steps to run performance tests.

1. Clone this repository using the following command.

```
git clone https://github.com/ballerina-platform/ballerina-performance
```

2. Run the Maven command ``mvn clean install`` from the repository root directory.

3. Change directory to `cloudformation/target` and extract distribution

```
$ tar -xf ballerina-performance-distribution-*.tar.gz
```

4. Estimate time to run the performance tests using `-t` flag on `./jmeter/run-performance-tests.sh` script. 
You can include or exclude scenarios. You can also change parameters as required.

```
$ ./jmeter/run-performance-tests.sh -t
```
    
See usage:

```
./jmeter/run-performance-tests.sh -h

Usage: 
./jmeter/run-performance-tests.sh [-u <concurrent_users>] [-b <message_sizes>] [-s <sleep_times>] [-m <heap_sizes>] [-d <test_duration>] [-w <warmup_time>]
   [-n <jmeter_servers>] [-j <jmeter_server_heap_size>] [-k <jmeter_client_heap_size>] [-l <netty_service_heap_size>]
   [-i <include_scenario_name>] [-e <include_scenario_name>] [-t] [-p <estimated_processing_time_in_between_tests>] [-h]

-u: Concurrent Users to test. Multiple users must be separated by spaces. Default "50 100 150 500 1000".
-b: Message sizes in bytes. Multiple message sizes must be separated by spaces. Default "50 1024 10240".
-s: Backend Sleep Times in milliseconds. Multiple sleep times must be separated by spaces. Default "0 30 500 1000".
-m: Application heap memory sizes. Multiple heap memory sizes must be separated by spaces. Default "2g".
-d: Test Duration in seconds. Default 900.
-w: Warm-up time in minutes. Default 5.
-n: Number of JMeter servers. If n=1, only client will be used. If n > 1, remote JMeter servers will be used. Default 1.
-j: Heap Size of JMeter Server. Default 4g.
-k: Heap Size of JMeter Client. Default 2g.
-l: Heap Size of Netty Service. Default 4g.
-i: Scenario name to to be included. You can give multiple options to filter scenarios.
-e: Scenario name to to be excluded. You can give multiple options to filter scenarios.
-t: Estimate time without executing tests.
-p: Estimated processing time in between tests in seconds. Default 60.
-h: Display this help and exit.
```

5. Go back to `cloudformation` directory and use `./run-performance-tests.sh` to run tests. 
Use flags used in step 4 without the `-t` flags after specifying flags for the `./run-performance-tests.sh`.
You can use `--` to indicate the end of command options.

For example:

```
./run-performance-tests.sh -f target/performance-ballerina-distribution-0.1.0-SNAPSHOT.tar.gz -k ~/keys/ballerina-perf-test.pem \
    -u https://product-dist.ballerina.io/downloads/0.981.1/ballerina-platform-linux-installer-x64-0.981.1.deb \
    -- -d 180 -w 1 -i passthrough_http -e https -u 100 -b 50 -s 0 -j 256m -k 256m -m 256m -l 256m
```

Please note that this script also needs an existing S3 Bucket name and the region of the S3 Bucket.

See usage:

```
./run-performance-tests.sh -h

Usage: 
./run-performance-tests.sh -f <ballerina_performance_distribution> -k <key_file> -u <ballerina_installer_url> [-n <key_name>]
   [-b <s3_bucket_name>] [-r <s3_bucket_region>]
   [-J <jmeter_client_ec2_instance_type>] [-S <jmeter_server_ec2_instance_type>]
   [-B <ballerina_ec2_instance_type>] [-N <netty_ec2_instance_type>]
   [-h] -- [run_performance_tests_options]

-f: The Ballerina Performance Distribution containing the scripts to run performance tests.
-k: The Amazon EC2 Key File.
-u: The Ballerina Installer URL.
-n: The Amazon EC2 Key Name. Default: ballerina-perf-test.
-b: The Amazon S3 Bucket Name. Default: ballerinaperformancetest.
-r: The Amazon S3 Bucket Region. Default: us-east-2.
-J: The Amazon EC2 Instance Type for JMeter Client. Default: t2.micro.
-S: The Amazon EC2 Instance Type for JMeter Server. Default: t2.micro.
-B: The Amazon EC2 Instance Type for Ballerina. Default: t2.micro.
-N: The Amazon EC2 Instance Type for Netty (Backend) Service. Default: t2.micro.
-h: Display this help and exit.
```

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community. To start contributing, read these [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md) for information on how you should go about contributing to our project.

Check the issue tracker for open issues that interest you. We look forward to receiving your contributions.

## License

Ballerina code is distributed under [Apache license 2.0](https://github.com/ballerina-platform/ballerina-lang/blob/master/LICENSE).

## Useful links

* The ballerina-dev@googlegroups.com mailing list is for discussing code changes to the Ballerina project.
* Chat live with us on our [Slack channel](https://ballerina-platform.slack.com/).
* Technical questions should be posted on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
