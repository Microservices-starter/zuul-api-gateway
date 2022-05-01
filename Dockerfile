FROM maven:3.8.5-jdk-11 as builder
WORKDIR /app
COPY . .
RUN mvn install

FROM openjdk:11.0.10-jre
WORKDIR /app
COPY --from=builder /app/target/zuul-0.0.1-SNAPSHOT.jar .
EXPOSE 8080
RUN rm -rf ROOT && mv zuul-0.0.1-SNAPSHOT.jar zuul.jar
CMD ["java", "-jar", "zuul.jar"] 