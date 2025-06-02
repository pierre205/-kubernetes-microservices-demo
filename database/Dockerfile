FROM postgres:15-alpine

# Set environment variables
ENV POSTGRES_DB=microservices_db
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres123

# Copy initialization scripts
COPY init.sql /docker-entrypoint-initdb.d/

# Copy custom postgresql.conf for better performance
COPY postgresql.conf /etc/postgresql/postgresql.conf

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1

# Expose port
EXPOSE 5432

# Custom entrypoint for logging
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
