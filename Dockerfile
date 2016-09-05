FROM perl:latest
MAINTAINER mitch.hulscher@nepworldwide.nl

ADD bin               /app/bin
ADD cpanfile          /app
ADD cpanfile.snapshot /app

RUN apt-get update \
 && apt-get install -y \
  jq \
  curl \
 && curl -o /tmp/zabbix-release.deb http://repo.zabbix.com/zabbix/3.0/debian/pool/main/z/zabbix-release/zabbix-release_3.0-1+jessie_all.deb \
 && dpkg -i /tmp/zabbix-release.deb \
 && apt-get update \
 && apt-get install -y zabbix-sender \
 && rm -f /tmp/zabbix-release.deb \
 && rm -rf /var/lib/apt/lists/* \
 && cd /app \
 && cpanm Carton \
 && carton install --deployment \
 && rm -rf local/cache

WORKDIR "/app"

EXPOSE "80"

ENTRYPOINT ["carton", "exec", "perl"]
CMD ["bin/app.pl", "daemon", "-l", "http://0.0.0.0:80"]
