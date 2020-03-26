FROM ruby:2.6.5

RUN apt-get update && apt-get install -y \
  build-essential \
  imagemagick \
  libmagic-dev \
  libreoffice \
  tesseract-ocr

RUN wget --quiet https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb && \
    echo "f4f3e0779d46579c63a76875e25e6b3d  wkhtmltox_0.12.5-1.buster_amd64.deb" > MD5SUMS && \
    md5sum -c MD5SUMS && \
    apt-get -qy install ./wkhtmltox_0.12.5-1.buster_amd64.deb && \
    rm -f wkhtmltox_0.12.5-1.buster_amd64.deb MD5SUMS

RUN gem install bundler

ENV INSTALL_PATH /var/www/colore

RUN mkdir -p $INSTALL_PATH

WORKDIR $INSTALL_PATH

RUN mkdir -p log
RUN mkdir -p tmp/pids

COPY Gemfile $INSTALL_PATH/Gemfile
COPY Gemfile.lock $INSTALL_PATH/Gemfile.lock

ENV RACK_ENV production

RUN bundle config set deployment 'true' && bundle

COPY bin ./bin
COPY config ./config
COPY lib ./lib
COPY config.ru ./
COPY unicorn.rb ./
COPY docker/colore/app.yml ./config

EXPOSE 9240

COPY docker/colore/docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["bundle", "exec", "unicorn"]
