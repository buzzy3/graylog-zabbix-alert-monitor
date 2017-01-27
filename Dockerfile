FROM melopt/perl-carton-base
MAINTAINER mitch.hulscher@nepworldwide.nl

RUN apt-get update \
 && apt-get install -y \
  jq \
  curl \
 && curl -o /tmp/zabbix-release.deb http://repo.zabbix.com/zabbix/3.0/debian/pool/main/z/zabbix-release/zabbix-release_3.0-1+jessie_all.deb \
 && dpkg -i /tmp/zabbix-release.deb \
 && apt-get update \
 && apt-get install -y zabbix-sender \
 && apt-get purge zabbix-release \
 && rm -f /tmp/zabbix-release.deb \
 && rm -rf /var/lib/apt/lists/*


EXPOSE "80"
CMD ["bin/app.pl", "daemon", "-m", "production", "-l", "http://0.0.0.0:80"]
