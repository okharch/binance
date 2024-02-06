# Use the official Docker Hub Postgres image
FROM postgres:14.1

# Install curl, unzip, cron, and postgresql-client
RUN apt-get update && apt-get install -y curl unzip cron postgresql-client

# Download and install migrate tool
RUN curl -L https://github.com/golang-migrate/migrate/releases/download/v4.17.0/migrate.linux-amd64.tar.gz | tar xvz && \
    mv migrate /usr/local/bin/

# Copy the migrations folder into the docker container
COPY ./migrations /migrations

#-- commented out to manually debug the image
# Run the rest of the commands as the `postgres` user created by the `postgres` Docker image
# Run the rest of the commands as the `postgres` user created by the `postgres` Docker image
#USER postgres
#
## Start PostgreSQL, wait for it to be ready, then create a PostgreSQL role named `docker` with `docker` as the password and
## then create a database `docker` owned by the `docker` role.
#RUN    /etc/init.d/postgresql start &&\
#    sleep 1 &&\
#    psql -p 5432 --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
#    createdb -O docker docker \
#
## Adjust PostgreSQL configuration so that remote connections to the
## database are possible.
#RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/14/main/pg_hba.conf
#
## And add `listen_addresses` to `/etc/postgresql/14/main/postgresql.conf`
#RUN echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf
#
## Add a cron job to run the update_exchange_info procedure once a day
#RUN echo "0 0 * * * psql -U docker -d docker -c 'CALL update_exchange_info();'" >> /etc/crontab
#
## Expose the PostgreSQL port
#EXPOSE 5432
#
## Add VOLUMEs to allow backup of config, logs and databases
#VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]
#
## Set the default command to run when starting the container
#CMD /etc/init.d/postgresql start && cron && migrate -path=/migrations -database=postgresql://docker:docker@localhost:5432/docker up && /usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main -c config_file=/etc/postgresql/14/main/postgresql.conf