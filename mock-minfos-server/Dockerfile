# Use the official Ballerina base image
FROM ballerina/ballerina:latest

# Set the working directory inside the container
WORKDIR /app

# Copy the Ballerina code into the working directory
COPY . .

# Compile the Ballerina program
# If you have a Ballerina project with ballerina.toml, use `bal build`.
RUN bal build

# Expose the service port
EXPOSE 8086

# Run the compiled Ballerina service
CMD ["bal", "run"]

