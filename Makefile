GITHUB_TOKEN?=
PERFORMANCE_COMMON_REPO?=https://github.com/heshanpadmasiri/performance-common.git
PERFORMANCE_COMMON_BRANCH?=ballerina-patch
AWS_PAGER=
PERFORMANCE_COMMON_PATH?=../performance-common
JAVA_HOME?=/home/ubuntu/jdk/jdk-17.0.13+11
KEY_FILE_PREFIX?=/home/ubuntu/perf
KEY_FILES=$(KEY_FILE_PREFIX)/*.p12
NETTY_JAR_WITH_DEP?=netty-http-echo-service-0.4.6-SNAPSHOT-jar-with-dependencies.jar
NETTY_JAR=netty-http-echo-service-0.4.6-SNAPSHOT.jar
NETTY_JAR_PATH=$(PERFORMANCE_COMMON_PATH)/components/netty-http-echo-service/target/$(NETTY_JAR_WITH_DEP)
PAYLOAD_GENERATOR_JAR=payload-generator-0.4.6-SNAPSHOT.jar
PAYLOAD_GENERATOR_JAR_PATH=$(PERFORMANCE_COMMON_PATH)/components/payload-generator/target/$(PAYLOAD_GENERATOR_JAR)
CLOUD_FORMATION_SCRIPTS=$(PERFORMANCE_COMMON_PATH)/distribution/scripts/cloudformation/*
JMETER_SCRIPTS=$(PERFORMANCE_COMMON_PATH)/distribution/scripts/jmeter/*
DIST_VER?=1.1.1-SNAPSHOT
DIST_NAME=ballerina-performance-distribution-$(DIST_VER)
PERF_TAR=$(DIST_NAME).tar.gz
PERF_TAR_PATH=./distribution/target/$(PERF_TAR)
BUILD_DIR=./build
BAL_VER?=2201.10.1
BAL_INSTALLER_NAME?=ballerina-$(BAL_VER)-swan-lake-linux-x64.deb
DEB_URL?=https://dist.ballerina.io/downloads/$(BAL_VER)/ballerina-$(BAL_VER)-swan-lake-linux-x64.deb
UNPACK_STAMP=.unpack.stamp
NETTY_REPLACE_STAMP=.netty.stamp
SCRIPT_PATH_STAMP=.template.stamp
KEY_STAMP=.key.stamp
REPACK_STAMP=.repack.stamp
DEB_STAMP=.deb.stamp
DIST_STAMP=.dist.stamp

dist: $(DIST_STAMP)

run: $(DIST_STAMP)
	chmod +x run.sh
	./run.sh $(DIST_NAME) $(BAL_INSTALLER_NAME) 2>&1 > run.log

$(PERFORMANCE_COMMON_PATH):
	git clone --depth=1 $(PERFORMANCE_COMMON_REPO) $(PERFORMANCE_COMMON_PATH) -b $(PERFORMANCE_COMMON_BRANCH)

$(DIST_STAMP): $(REPACK_STAMP) $(DEB_STAMP)
	tar -czf $(BUILD_DIR)/dist.tar.gz -C $(BUILD_DIR) $(PERF_TAR) ballerina-$(BAL_VER)-swan-lake-linux-x64.deb
	touch $(DIST_STAMP)

$(NETTY_JAR_PATH) $(PAYLOAD_GENERATOR_JAR_PATH): $(PERFORMANCE_COMMON_PATH)
	cd $(PERFORMANCE_COMMON_PATH) && mvn package

$(DEB_STAMP): $(REPACK_STAMP)
	cd $(BUILD_DIR) && curl -L -o ballerina-$(BAL_VER)-swan-lake-linux-x64.deb $(DEB_URL)
	touch $(DEB_STAMP)

$(REPACK_STAMP): $(KEY_STAMP) $(NETTY_REPLACE_STAMP) $(SCRIPT_PATH_STAMP)
	mkdir -p $(BUILD_DIR)/dist/$(DIST_NAME)
	mv $(BUILD_DIR)/dist/ $(BUILD_DIR)/$(DIST_NAME)
	tar -czf $(BUILD_DIR)/$(DIST_NAME).tar.gz -C $(BUILD_DIR) $(DIST_NAME)
	rm -rf $(BUILD_DIR)/$(DIST_NAME)
	touch $(REPACK_STAMP)

$(PERF_TAR_PATH):
	mvn clean package

$(KEY_STAMP): $(KEY_FILES) $(UNPACK_STAMP)
	cp $(KEY_FILES) $(BUILD_DIR)/dist
	touch $(KEY_STAMP)

$(SCRIPT_PATH_STAMP): $(UNPACK_STAMP)
	cp -r $(CLOUD_FORMATION_SCRIPTS) $(BUILD_DIR)/dist/cloudformation/
	cp -r $(JMETER_SCRIPTS) $(BUILD_DIR)/dist/jmeter/
	touch $(SCRIPT_PATH_STAMP)

$(NETTY_REPLACE_STAMP): $(NETTY_JAR_PATH) $(UNPACK_STAMP) $(PAYLOAD_GENERATOR_JAR_PATH)
	rm -f $(BUILD_DIR)/dist/netty-service/$(NETTY_JAR)
	cp $(NETTY_JAR_PATH) $(BUILD_DIR)/dist/netty-service/$(NETTY_JAR)
	cp $(PAYLOAD_GENERATOR_JAR_PATH) $(BUILD_DIR)/dist/payloads/$(PAYLOAD_GENERATOR_JAR)
	touch $(NETTY_REPLACE_STAMP)

$(UNPACK_STAMP): $(PERF_TAR_PATH) 
	mkdir -p $(BUILD_DIR)/dist
	tar -xzf $(PERF_TAR_PATH) -C $(BUILD_DIR)/dist
	touch $(UNPACK_STAMP)

clean:
	cd $(PERFORMANCE_COMMON_PATH) && mvn clean
	mvn clean
	rm -rf *.stamp
	rm -rf $(BUILD_DIR)

.PHONY: clean dist run
