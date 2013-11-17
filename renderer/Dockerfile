FROM node

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
RUN apt-get update && apt-get install -y gdebi && gdebi -n wkhtmltox_0.12.5-1.stretch_amd64.deb

WORKDIR /app

ADD hackmyresume .
RUN npm install -g
ADD themes .
RUN bash -e -c "for THEME in \$(cat themes); do echo \$THEME; npm install jsonresume-theme-\$THEME; done"
