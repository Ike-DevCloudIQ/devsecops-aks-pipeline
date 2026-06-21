# Use an official Tomcat image as a base image
FROM tomcat:9.0.14-jre8-alpine

LABEL maintainer="github.com/asecurityguru"

# Remove default Tomcat application
RUN rm -rf /usr/local/tomcat/webapps/ROOT/*

# Copy your web application to the Tomcat webapps directory
COPY webapp/ /usr/local/tomcat/webapps/ROOT/

# Change the default shell to bash
RUN ln -sf /bin/bash /bin/sh

# Create and switch to a non-root user for runtime hardening
RUN addgroup -S appgroup \
    && adduser -S -G appgroup appuser \
    && chown -R appuser:appgroup /usr/local/tomcat
USER appuser

# Expose the default Tomcat port
EXPOSE 8080

# Start Tomcat when the container starts
CMD ["catalina.sh", "run"]
