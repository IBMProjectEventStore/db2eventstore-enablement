# Reactive Summit, Montreal, Canada - Oct 22, 2018

##### Introduction
This lab will review & run a end to end application written on top of the IBM Db2 Event Store. The App implements a Weather prediction model using the following concepts:
* [The IBM DB2 Event Store](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/welcome.html)
* [The IBM Data Science Experience local](https://datascience.ibm.com/local)
* [The Lightbend Fast Data Platform](https://www.lightbend.com/products/fast-data-platform)
* [Apache Spark](http://spark.apache.org)
* [Apache Kafka](http://kafka.apache.org)
* [Akka](https://akka.io/)
* [Grafana](https://grafana.com/)

##### YouTube Video Demo

![](overallArchitecture.png)(https://youtu.be/q9LmWtZAAdU "Reactive Summit 2018 Demo")

##### Tools required

* SBT
* Terminal Window
* Git
* IBM Db2 Event Store
* IntelliJ
* Grafana

---

## Lab Use Case

_I need fast access to real time data to analyze it, execute machine learning and leverage these models for predictive analytics._

---

## Presentation of the IBM Db2 Event Store & Fast Data

![Fast Data Ingest & Analytics Oct 22](FastDataIngestAnalyticsOct22.pptx)

---

## IBM Db2 Event Store Reference Architecture

![](db2eventstore.png)

---

## Reference Architecture

Final architecture of the implementation looks as follows

![](overallArchitecture.png)

This lab presents the following technology:
- **Akka* is an advanced toolkit and message-driven runtime based on the Actor Model that helps development teams build the right foundation for successful microservices architectures and streaming data pipelines.
- **Apache Kafka** provides scalable, reliable, and durable short-term storage of data, organized into topics (like traditional message queues), which can be consumed by downstream applications.
- We have an application named KillrWeather that will process those messages and stream them to the **IBM Db2 Event Store** where they can be visualized graphically in Grafana
- A **machine learning** model that is trained on the incoming data so that it be later used to score the in-flight data in order to predict temperatures
- A model serving component that receives the online model and does the scoring. Predicted values are then associated with their incoming Event

---

## Prerequisites

* The IBM Db2 Event Store Developer Edition 1.1.4 (requires Docker)
* IntelliJ CE
* SBT
* Docker Version 18.06.1-ce-mac73 (26764)

---

## Installing IBM Db2 Event Store

#####  Installing the IBM Db2 Event Store
```bash

```

#####  Cleaning up the IBM Db2 Event Store metadata
```bash
cd Library/Application\ Support/ibm-es-desktop
rm -rf zookeeper alluxio ibm
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
```

---

## Notebooks

##### Tools
* IBM Db2 Event Store

##### Objectives
* Understand how to use a Jupyter Notebook to interact with the IBM Db2 Event Store
* Understand the IBM Db2 Event Store Scala API

##### Lab Assignments
```bash
* In the IBM Db2 Event Store
* Run the Notebook *Introduction to IBM Db2 Event Store Scala API*
* Run the Notebook *Analyze customers' purchasing data in real-time*
_Make sure to allocate enough Docker Memory_
```

---

## Kafka Ingest

##### Tools 
* SBT
* Terminal Window
* Git
* IBM Db2 Event Store

##### Objectives
* Understand how to stream data into the IBM Db2 Event Store with Kafka

##### Installing Sbt 0.13.16
```bash
sbt sbt-version
...
...
```

##### Lab Assignment
```bash
* Open a Terminal window
* Follow the direction from the following GIT repo on how to setup
* https://github.com/IBMProjectEventStore/db2eventstore-kafka
sbt "eventStream/run -localBroker true -kafkaBroker localhost:9092 -topic estopic -eventStore localhost:1100 -database TESTDB -user admin  -password password -metadata ReviewTable -streamingInterval 5000 -batchSize 10"
sbt "dataLoad/run -localBroker true -kafkaBroker localhost:9092 -tableName ReviewTable -topic estopic -group group -metadata sensor -metadataId 238 -batchSize 10"
```

---

## REST API

##### Tools 
* Terminal Window
* Curl
* IBM Db2 Event Store

##### Objectives
* Understand the IBM Db2 Event Store REST API

##### Reference
* [IBM DB2 Event Store Documentation](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/welcome.html)
* [IBM DB2 Event Store Rest API](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/develop/rest-api.html)

##### Lab Assignment
```bash
* Open a Terminal window
* SBT ingest with kafka into the IBM Db2 Event Store (with the generator)
* Run the following curl commands

* Navigating the Catalog & Data:
curl -X POST -H "Content-Type: application/json" -H "authorization: Bearer token" 'http://0.0.0.0:9991/com/ibm/event/api/v1/init/engine?engine=173.19.0.1:1100&rContext=Desktop'
curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer token" http://0.0.0.0:9991/com/ibm/event/api/v1/oltp/databases
curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer token" http://0.0.0.0:9991/com/ibm/event/api/v1/oltp/tables?databaseName=TESTDB

* Running Spark Query:
curl -k -i -X POST -H "Content-Type: application/json" -H "authorization: Bearer token" --data "{\"sql\": \"select * from ReviewTable\"}" "http://0.0.0.0:9991/com/ibm/event/api/v1/spark/sql?databaseName=TESTDB&tableName=ReviewTable&format=json"
```

---

## Grafana integration

##### Tools 
* Grafana
* Terminal Window
* Curl
* IBM Db2 Event Store

##### Objectives
* Understand how to visualize the ingested data

##### Reference
[Installing Grafana](https://grafana.com/grafana/download?platform=mac)
[Grafana Data Source Git Repo](https://github.com/IBMProjectEventStore/db2eventstore-grafana)

##### Lab Assignment
```bash
- Grafana setup
brew update 
brew install grafana
brew services restart grafana

* Check Grafana:
http://localhost:3000 [admin/admin]

* Install IBM Db2 Event Store plugin:
mkdir -p /usr/local/var/lib/grafana/plugins/db2-event-store
mv db2-event-store-grafana.tar /usr/local/var/lib/grafana/plugins/db2-event-store
cd /usr/local/var/lib/grafana/plugins/db2-event-store
tar -zxvf db2-event-store-grafana.tar
brew services restart grafana

http://localhost:3000 [admin/admin]
Add a Db2 Event Store Data Source

 
```

---

## KillrWeather Application without ML

##### Tools 
* Terminal Window
* Curl
* IBM Db2 Event Store
* IntelliJ

##### Objectives
* Understand the end to end application

##### Reference
* [IBM DB2 Event Store Documentation](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/welcome.html)
* [IBM DB2 Event Store Rest API](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/develop/rest-api.html)

##### Lab Assignment

```bash
```

---

## KillrWeather Application with ML

##### Tools 
* Terminal Window
* Curl
* IBM Db2 Event Store
* IntelliJ

##### Objectives
* Understand the end to end application

##### Reference
* [IBM DB2 Event Store Documentation](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/welcome.html)
* [IBM DB2 Event Store Rest API](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/develop/rest-api.html)

##### Lab Assignment