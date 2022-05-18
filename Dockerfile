
FROM debian:stable

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
      r-base r-base-dev git nodejs npm r-cran-magrittr \
      r-cran-data.table apt-utils && \
    apt-get clean

RUN cd root && \
    git clone https://github.com/tonyfischetti/bow-wow && \
    cd bow-wow && npm install && npm install gulp-cli --global

WORKDIR /root/bow-wow

CMD gulp

