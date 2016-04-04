FROM ruby:2.1

RUN apt-get update
RUN apt-get install -y libreoffice
RUN apt-get install -y poppler-utils
RUN apt-get install -y tesseract-ocr
RUN apt-get install -y wkhtmltopdf

RUN mkdir /colore
WORKDIR /colore

RUN apt-get -y install \
  libmagic-dev \
  libxml2-dev \
  libxslt-dev

ADD ./Gemfile /colore/
ADD ./Gemfile.lock /colore/

RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install

# We use the Debian version instead
RUN rm /usr/local/bundle/bin/wkhtmltopdf

ADD ./ /colore/

RUN (cd /colore && git log --format="%H" -n 1 > REVISION && rm -rf .git)
