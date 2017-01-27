FROM melopt/perl-carton-base
MAINTAINER mitch.hulscher@nepworldwide.nl
EXPOSE "8080"
CMD ["bin/app.pl", "daemon", "-m", "production", "-l", "http://0.0.0.0:8080"]
