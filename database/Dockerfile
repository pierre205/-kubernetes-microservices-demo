FROM postgres:15-alpine

# Set environment variables
ENV POSTGRES_DB=microservices_db
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres123

# Copy initialization scripts
COPY init.sql /docker-entrypoint-initdb.d/

# Copy custom postgresql.conf for better performance
COPY postgresql.conf /etc/postgresql/postgresql.conf

# Health check (amélioré)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD pg_isready -U postgres || exit 1

# Expose port
EXPOSE 5432

# Custom entrypoint with PROPER path to avoid infinite loop
COPY custom-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
