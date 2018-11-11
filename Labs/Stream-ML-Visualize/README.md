# Learn how to stream & visualize your data with the IBM Db2 Event Store


##### Introduction
This lab will review & run an end to end application written on top of the IBM Db2 Event Store. The App implements a Weather prediction model using the following products & projects:
* [The IBM DB2 Event Store](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/welcome.html)
* [The IBM Data Science Experience local](https://datascience.ibm.com/local)
* [The Lightbend Fast Data Platform](https://www.lightbend.com/products/fast-data-platform)
* [Apache Spark](http://spark.apache.org)
* [Apache Kafka](http://kafka.apache.org)
* [Akka](https://akka.io/)
* [Grafana](https://grafana.com/)

##### YouTube Video Demo

As a reference, the following video was recorded when running the entire application on top of the IBM Fast Data Platform. In this lab, in order to simplify our runtime configuration and clarity of understanding, the App is made to run standalone against the IBM Db2 Event Store Dev. Edition.

![](overallArchitecture.png)(https://youtu.be/q9LmWtZAAdU "Reactive Summit 2018 Demo")

##### Tools required

* SBT 0.13.16
* MacOS Terminal Window
* Git
* IBM Db2 Event Store 1.1.4
* IntelliJ 2017.3
* Grafana 5.3.1
* Docker 18.06.1-ce

---

## Lab Use Case

_I need fast access to real time data to analyze it, execute machine learning and leverage these models for predictive analytics._

---

## Presentation of the IBM Db2 Event Store & Fast Data

See the companion presentation:
* `FastDataIngestAnalyticsOct22.pptx`

---

## IBM Db2 Event Store Reference Architecture

![](db2eventstore.png)

---

## Reference Architecture

Final architecture of the implementation looks as follows

![](overallArchitecture.png)

This lab presents the following technology:
- **Akka** is an advanced toolkit and message-driven runtime based on the Actor Model that helps development teams build the right foundation for successful microservices architectures and streaming data pipelines.
- **Apache Kafka** provides scalable, reliable, and durable short-term storage of data, organized into topics (like traditional message queues), which can be consumed by downstream applications.
- We have an application named KillrWeather that will process those messages and stream them to the **IBM Db2 Event Store** where they can be visualized graphically in Grafana
- A supervised learning **Machine Learning** model that is trained on the incoming data so that it be later used to score the in-flight data in order to predict temperatures
-- The algorithm is given training data which contains the "correct answer" for each event
- A model serving component that receives the online model and does the scoring. Predicted values are then associated with their incoming Event

---

## Prerequisites

In the course of this lab, we will provide the exact version number locally tested. Feel free to adjust this for your own environment. Make sure, however, to maintain compatibility.

* The IBM Db2 Event Store Developer Edition 1.1.4
* IntelliJ CE 2017.3
* SBT 0.13.16 (version tested)
* Docker Version 18.06.1-ce-mac73 (26764)

---

## Installing IBM Db2 Event Store

##### References
[IBM Db2 Dev Edition](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/desktop/welcome.html)

##### Increase Docker CPU/Mem
* 6 CPU / 8 GB

#####  Installing the IBM Db2 Event Store
```bash
** Download the platfom specific & latest installer
*** https://github.com/IBMProjectEventStore/EventStore-DeveloperEdition/releases

** MacOS & Windows **
* Start the installer (dmg or exe) and accept all defaults
** This operation may take some time based on your bandwith
```

#####  Cleaning up the IBM Db2 Event Store metadata

In case, the IBM Db2 Event Store Dev. Edition 1.1.4 docker container needs to be reinitialized, the following procedure can be applied. This will remove the containers and delete all the data and metadata.

Reset the IBM Db2 Event Store Dev. Edition 1.1.4:

```bash
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
cd ~/Library/Application\ Support/ibm-es-desktop
rm -rf zookeeper alluxio ibm
```


---
Understanding Notebooks, IBM Db2 Event Store and its Scala Client API
---

## Notebooks

##### Tools
* IBM Db2 Event Store

##### Objectives
* Understand how to use a Jupyter Notebook to interact with the IBM Db2 Event Store
* Understand the IBM Db2 Event Store Scala API

##### References
[Db2 Event Store Scala API](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/develop/dev-guide.html)

##### Lab Assignments
```bash
* In the IBM Db2 Event Store
* Run the Notebook *Introduction to IBM Db2 Event Store Scala API*
** Run all the Cells
** Review of the Event Store Scala API
** Understanding the Event Store SparkSQL query architecture
** Understanding querying the Db2 Event Store with different Snapshot settings
*** Review of the IBM Db2 Event Store Reference Architecture
_Make sure to allocate enough Docker Memory_
```

##### Lab Assignment
```bash
* Stop the kernel for the running notebooks
* Create a new Scala notebook and create a new table named ReactiveSummit
* Drop *ReviewTable* & *ReactiveSummit* table
```


---
Understanding Kafka & IBM Db2 Event Store
---

## Kafka Ingest

##### Tools 
* SBT
* Terminal Window
* Git
* IBM Db2 Event Store

##### Objectives
* Understand how to stream data into the IBM Db2 Event Store with Kafka

##### References
[Installing sbt](https://www.scala-sbt.org/download.html)
[Kafka Data Source Git Repo](https://github.com/IBMProjectEventStore/db2eventstore-kafka)

##### Installing Sbt 0.13.16
```bash
* sbt supplied with archive or install on your own
./bin/sbt sbt-version
* Should be at 0.13.16 level 
```

##### Lab Assignment
```bash
* Open a Terminal window
* Follow the direction from the following GIT repo on how to setup
* https://github.com/IBMProjectEventStore/db2eventstore-kafka
sbt "eventStream/run -localBroker true -kafkaBroker localhost:9092 -topic estopic -eventStore localhost:1100 -database TESTDB -user admin -metadata sensor -password password -metadata ReviewTable -streamingInterval 5000 -batchSize 10"
sbt "dataLoad/run -localBroker true -kafkaBroker localhost:9092 -tableName ReviewTable -topic estopic -group group -metadata sensor -metadataId 238 -batchSize 10"
** Understand the parameters provided to the connector & generator
*** Modify the connector batch size
** Stop the Ingest & Generator
```


---
Understanding REST & IBM Db2 Event Store
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
Data Visualization
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
wget https://github.com/IBMProjectEventStore/db2eventstore-grafana/files/2019003/db2-event-store-grafana.tar.zip
mkdir -p /usr/local/var/lib/grafana/plugins/db2-event-store
mv db2-event-store-grafana.tar /usr/local/var/lib/grafana/plugins/db2-event-store
cd /usr/local/var/lib/grafana/plugins/db2-event-store
tar -zxvf db2-event-store-grafana.tar
brew services restart grafana

* Initialize the REST Server:
    * If you have not run the REST section above, make sure to propertly initialize the REST Server
curl -X POST -H "Content-Type: application/json" -H "authorization: Bearer token" 'http://0.0.0.0:9991/com/ibm/event/api/v1/init/engine?engine=173.19.0.1:1100&rContext=Desktop'

* Login to Grafana:
    * http://localhost:3000 [admin/admin]
        * Add a Db2 Event Store Data Source

* Restart the generator and kafka stream
    * Add a new Dashboard
        * Create a new graph and visualize the incoming data for ReviewTable
```
**References & Visualization**

![](dataSource.png)

![](dataSourceSave.png)

![](grafana_kafka.png)

---
End to End Application with KillrWeather
---

## KillrWeather Application without ML

##### Tools 
* Terminal Window
* SBT
* Curl
* IBM Db2 Event Store
* IntelliJ

##### Objectives
* Understand & Run the end to end application

##### Reference
* [IBM DB2 Event Store Documentation](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/welcome.html)
* [IBM DB2 Event Store Rest API](https://www.ibm.com/support/knowledgecenter/en/SSGNPV_1.1.2/eventstore/develop/rest-api.html)
* [KillrWeather Git Repo](https://github.com/lightbend/fdp-killrweather-event-store)

##### Lab Assignments

```bash
- KillRWeather Repo Setup
git clone git@github.com:lightbend/fdp-killrweather-event-store.git
* Understand the module structure

- IntelliJ Setup
* Import Project
* Select the project root directory
* Select sbt as the project type
* Use the default settings for sbt. Use JDK 1.8 if it's not shown as the default.

- Compile the code
* Open a terminal window in IntelliJ
sbt clean
sbt compile

* Run the sample
```

**Data ingest**
![](dataIngest.png)

**Streaming App**
![](streamingApp.png)

```bash
* Stop the ingest
* Run a REST API call to find out how many rows have been ingested in the table "raw_weather_data"
```


---
Understanding Machine Learning
---

## KillrWeather Application with ML

##### Tools 
* Terminal Window
* Curl
* IBM Db2 Event Store
* IntelliJ

##### Objectives
* Understand ML

##### Reference
* [Spark ML](https://spark.apache.org/docs/1.2.2/ml-guide.html)
* [Jean-Francois Puget Feedback loop](https://www.kdnuggets.com/2017/06/practical-guide-machine-learning-understand-differentiate-apply.html)

##### Lab Assignment
```bash
* In IBM Db2 Event Store Desktop
** Add Notebooks
** Select "Weather+Prediction+Model.ipynb"
*** We won't have the SPSS libraries in today's environment, but this is a good sample to have, for reference
** Select "Weather+Spark+ML.ipynb" - Using SparkML instead
*** Run the cells
** Understand the different between training_data & test_data
```

---
Understanding Scoring
---

## KillrWeather Application with ML and Feedback Loop

##### Tools 
* Terminal Window
* Curl
* IBM Db2 Event Store
* IntelliJ

##### Objectives
* Understand Scoring

##### Lab Assignment
```bash
* Which table will carry the new prediction with any given Event?

* KillrWeather
** In IntelliJ, restart Ingest
** In IntelliJ, run the ModelServer & ModelListener

* Push the PMML over to the Model listener

cd <PATH>/fdp-killrweather-event-store/ml-model
curl -H "Content-Type: application/json" -X POST -d @722020:12839 http://localhost:5000/model
curl -H "Content-Type: application/json" -X POST -d @722950:23174 http://localhost:5000/model
curl -H "Content-Type: application/json" -X POST -d @724940:23234 http://localhost:5000/model
curl -H "Content-Type: application/json" -X POST -d @725030:14732 http://localhost:5000/model
curl -H "Content-Type: application/json" -X POST -d @725300:94846 http://localhost:5000/model

* Query that table in REST to see the prediction
```


---
End 2 End visualization
---

## Data Visualization for KillrWeather Application with ML and Feedback Loop

##### Tools 
* Terminal Window
* Curl
* IntelliJ
* Grafana

##### Objectives
* Understand Scoring

##### Lab Assignment
```bash
* Create a new Grafana Dashboard and visualize 1 widgets daily_aggregate_temperature & daily_predicted_temperature
* You can import the pre-built dashboard *IBM Db2 Event Store Demo - Weather Prediction-1540236483059* to visualize all the events
You can also curl the data directly, using the REST API reviewed earlier, like this:
curl -k -i -X POST -H "Content-Type: application/json" -H "authorization: Bearer token" --data "{\"sql\": \"SELECT avg(value), avg(ts) FROM ReviewTable WHERE sensor=238 AND ts>=1540167276448 AND ts<=1540167576448 GROUP BY ts DIV 200\"}" "http://0.0.0.0:9991/com/ibm/event/api/v1/spark/sql?databaseName=TESTDB&tableName=ReviewTable&format=json"
```
