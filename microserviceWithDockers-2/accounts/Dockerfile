#Start with a base image containing java runtime
FROM eclipse-temurin:25-jre-ubi10-minimal

#Infomation around who maintains the  image
LABEL "image.author"="saurabh@shukla.com"

#add the application's jar to image
COPY target/accounts-0.0.1-SNAPSHOT.jar accounts.jar

#Excute the application
ENTRYPOINT ["java", "-jar","accounts.jar"]