#!/bin/bash

echo "Dist name: $1"
echo "Intaller name: $2"
mkdir -p ./tmp
cp ./build/dist.tar.gz ./tmp
cd ./tmp
tar -xvf dist.tar.gz
tar -xvf $1.tar.gz
cd $1
./cloudformation/run-performance-tests.sh \
-u heshanp@wso2.com \
-f ../$1.tar.gz \
-k /home/ubuntu/perf/bhashinee-ballerina.pem \
-n bhashinee-ballerina \
-j /home/ubuntu/perf/apache-jmeter-5.1.1.tgz \
-o /home/ubuntu/perf/jdk-8u345-linux-x64.tar.gz \
-g /home/ubuntu/perf/gcviewer-1.36.jar \
-s 'wso2-ballerina-test1-' \
-b ballerina-sl-9 \
-r 'us-east-1' \
-J c5.xlarge -S c5.xlarge -N c5.xlarge -B t3a.small \
-i ../$2 \
-- -d 360 -w 180 \
-u 100 \
-b 500 \
-s 0 -j 2G -k 2G -m 1G -l 2G
