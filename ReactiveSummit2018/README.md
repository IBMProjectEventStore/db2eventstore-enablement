# Reactive Summit 2018

This lab will run an end to end application. We are going to review & run a full end to end application that we wrote on top of the IBM Fast Data Platform: A simplistic Weather prediction model

References:
* [IBM DB2 Event Store](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/welcome.html)
* [IBM Data Science Experience local](https://datascience.ibm.com/local)
* [Lightbend Fast Data Platform](https://www.lightbend.com/products/fast-data-platform)
* [Apache Spark](http://spark.apache.org)
* [Apache Kafka](http://kafka.apache.org),
* [Akka](https://akka.io/)
* [Grafana](https://grafana.com/)

## Sample Use Case

_I need fast access to real time data to analyze it, execute machine learning and leverage these models for predictive analytics._

## Demo

**TBD** Add youtube video 

## Presentation of the IBM Db2 Event Store

**TBD** Add PPT

## IBM Db2 Event Store Reference Architecture

![](diagrams/db2eventstore.png)

## Reference Architecture

Final architecture of the implementation looks as follows

![](diagrams/overallArchitecture.png)

This lab will present the following technology:
- Akka is an advanced toolkit and message-driven runtime based on the Actor Model that helps development teams build the right foundation for successful microservices architectures and streaming data pipelines.
- Apache Kafka provides scalable, reliable, and durable short-term storage of data, organized into topics (like traditional message queues), which can be consumed by downstream applications.
- We have an application named KillrWeather that will process those messages and stream them to the IBM Db2 Event Store where they can be visualized graphically in Grafana
- A machine learning model that is trained on the incoming data so that it be later used to score the in-flight data in order to predict temperatures
- A model serving component that receives the online model and does the scoring. Predicted values are then associated with their incoming Event

## Prerequisites

* The IBM Db2 Event Store Developer Edition 1.1.4 (requires Docker)
* IntelliJ CE
* SBT
* Docker Version 18.06.1-ce-mac73 (26764)

## Installing IBM Db2 Event Store

* Installing the IBM Db2 Event Store
```bash
```

* Cleaning up the IBM Db2 Event Store metadata
```bash
cd Library/Application\ Support/ibm-es-desktop
rm -rf zookeeper alluxio ibm
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
```

## Notebooks

*Tools*: 
* IBM Db2 Event Store

*Objectives*: 
* Understand how to use a Jupyter to interact with the IBM Db2 Event Store
* Understand the IBM Db2 Event Store Scala API

*Lab*:
* Running *Introduction to IBM Db2 Event Store Scala API*
* Running *Analyze customers' purchasing data in real-time*
_Make sure to allocate enough Docker Memory_

## Kafka Ingest

*Tools*: 
* SBT
* Terminal Window
* Git
* IBM Db2 Event Store

*Objectives*:
* Understand how to stream data into the IBM Db2 Event Store with Kafka

*Lab*:
https://github.com/IBMProjectEventStore/db2eventstore-kafka

## REST API

*Tools*: 
* Terminal Window
* Curl
* IBM Db2 Event Store

*Objectives*:
* Understand the IBM Db2 Event Store REST API

*Reference*:
* [IBM DB2 Event Store Documentation](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/welcome.html)
* [IBM DB2 Event Store Rest API](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/develop/rest-api.html)

*Lab*:
* Navigating the Catalog & Data
```bash
curl -X POST -H "Content-Type: application/json" -H "authorization: Bearer token" 'http://0.0.0.0:9991/com/ibm/event/api/v1/init/engine?engine=173.19.0.1:1100&rContext=Desktop'
curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer token" http://0.0.0.0:9991/com/ibm/event/api/v1/oltp/databases
curl -X GET -H "Content-Type: application/json" -H "authorization: Bearer token" http://0.0.0.0:9991/com/ibm/event/api/v1/oltp/tables?databaseName=TESTDB
```

* Running Spark Query
```bash
curl -k -i -X POST -H "Content-Type: application/json" -H "authorization: Bearer token" --data "{\"sql\": \"select * from ReviewTable\"}" "http://0.0.0.0:9991/com/ibm/event/api/v1/spark/sql?databaseName=TESTDB&tableName=ReviewTable&format=json"
```

