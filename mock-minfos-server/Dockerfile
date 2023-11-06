# Builder stage
FROM ballerina/ballerina:latest AS builder


# Set the working directory in the builder stage
WORKDIR /home/ballerina

# Copy the Ballerina code to the working directory
COPY . .

# Compile the Ballerina program
# As 'ballerina' user
USER root
RUN bal build
# Runtime stage
FROM ballerina/ballerina:latest


# Set the working directory in the runtime stage
WORKDIR /home/ballerina

# Copy the compiled package from the builder stage
COPY --from=builder /home/ballerina/target/bin/soapservice.jar .

# Change ownership to the ballerina user
#RUN chown ballerina:ballerina soapservice.jar

# Switch to ballerina user
USER ballerina

# Expose the service port
EXPOSE 8086

# Command to run the Ballerina service
CMD ["bal", "run", "soapservice.jar"]

