# Use an appropriate base image
FROM amazonlinux:2

# Install jq and AWS CLI
RUN yum install -y jq aws-cli && \
    yum clean all

# Set the working directory inside the container
WORKDIR /app

# Copy the Bash script into the container
COPY shutdown.sh /app/

# Set execute permissions for the script
RUN chmod +x /app/shutdown.sh

# Run the Bash script when the container starts
CMD ["./shutdown.sh"]
