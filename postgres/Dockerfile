FROM postgres:latest

RUN apt-get update \
    && apt-get install -y nano git make \
    && apt-get clean && apt-get autoremove

# clone the postgres build scripts into a local folder
# and create a directory for the data
RUN mkdir mimic-code \
    && cd mimic-code \
    && git init \ 
    && git remote add -f origin https://github.com/MIT-lcp/mimic-code \
    && git config core.sparseCheckout true \
    && echo "buildmimic/postgres/" >> .git/info/sparse-checkout \
    && git pull origin master \
    && cp -r buildmimic /docker-entrypoint-initdb.d/ \
    && mkdir /mimic_data

# Add setup.sh to the entrypoint
ADD setup.sh /docker-entrypoint-initdb.d/
