# onebusaway-script

This is a collection of some scripts we're using to run OneBusAway in Austin. Feel free to copypasta whatever you'd like. Who knows if it works.

###  To use this script:

Choose combined or separate webapps. :warning: Combined currently does not work.

Inside will be either one or more `data-sources.xml` files (in xmlfiles folder for separate).

You must edit these to match your settings.

```
separate/xmlfiles/onebusaway-api-webapp/data-sources.xml
separate/xmlfiles/onebusaway-transit-data-federation-webapp/data-sources.xml
separate/xmlfiles/onebusaway-webapp/data-sources.xml
```

Once you have done this, you can optionally edit the script itself if you need to tweak it. All the variables are provided at the top for easier editing.

Finally, don't forget to edit this block in the script:
```
#Load Transit Bundle Data into SQL Database
echo "Sending Bundle Data to Postgres Database... (This takes a while)"
java -classpath $DATABASELOADERFILE:$PSQLJDBCDRIVERFILE \
 org.onebusaway.gtfs.GtfsDatabaseLoaderMain \
 --driverClass=org.postgresql.Driver \
 --url=jdbc:postgresql://localhost/oba \
 --username=vincentliao \
 --password="" \
 ./gtfs.zip
echo "Complete!"
```
Username and password will obviously be different, but you could also add it to a different database type using the respective JDBC driver.

Then all you have to do is type:

```
cd separate
bash fresh_install_separate.sh
```

or

```
cd combined
bash fresh_install_combined.sh
```

to start the script!


## Requirements

For ubuntu 14, we needed to install:

```
sudo apt-get install git
sudo apt-get install openjdk-7-jdk
sudo apt-get install maven
```

You'll also need to set up a database and point the data-sources.xml to it. We used Postgres on AWS RDS.


## Updating the server

Deploying GTFS url changes to the austin OneBusAway server

```
# Deploying GTFS url changes to the austin OneBusAway server
#
# First make any config changes to /var/www/onebusaway-script/separate/xmlfiles/onebusaway-transit-data-federation-webapp/data-sources.xml
# The relevant section is usually
# <bean class="org.onebusaway.transit_data_federation.impl.realtime.gtfs_realtime.GtfsRealtimeSource">
#     <property name="tripUpdatesUrl" value="http://localhost:6996/protobuf?url=https://data.texas.gov/download/rmk2-acnw/application/octet-stream" />
#     <property name="vehiclePositionsUrl" value="http://localhost:6996/protobuf?url=https://data.texas.gov/download/eiei-9rpf/application/octet-stream" />
#     <property name="alertsUrl" value="https://data.texas.gov/download/nusn-7fcn/application/octet-stream" />
#     <!-- Optionally set the refresh interval - how often we query the URLs, in seconds (default=30) -->
#     <property name="refreshInterval" value="5"/>
# </bean>

BUILD_DIR='/var/www/onebusaway-script/separate/obatemp/'
CONFIG_DIR='/var/www/onebusaway-script/separate/xmlfiles/'

cp $CONFIG_DIR/onebusaway-transit-data-federation-webapp/data-sources.xml $BUILD_DIR/onebusaway-application-modules/onebusaway-transit-data-federation-webapp/src/main/resources/
cd $BUILD_DIR/onebusaway-application-modules/onebusaway-transit-data-federation-webapp
mvn package

bash $BUILD_DIR/apache-tomcat-8.0.30/bin/shutdown.sh
cp $BUILD_DIR/onebusaway-application-modules/onebusaway-transit-data-federation-webapp/target/onebusaway-transit-data-federation-webapp.war $BUILD_DIR/apache-tomcat-8.0.30/webapps
bash $BUILD_DIR/apache-tomcat-8.0.30/bin/startup.sh

tail -f $BUILD_DIR/apache-tomcat-8.0.30/logs/*
```

## License

Released to the public domain under [the Unlicense](http://unlicense.org/).

To the extent possible under law, [Vincent Liao](https://github.com/vinceis1337) and other Open Austin contributors have waived all copyright and related or neighboring rights to this work.
