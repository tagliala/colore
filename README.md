Colore
======

[![Build Status](https://travis-ci.org/ifad/colore.svg)](https://travis-ci.org/ifad/colore)
[![Inline docs](http://inch-ci.org/github/ifad/colore.svg?branch=master)](http://inch-ci.org/github/ifad/colore)
[![Code Climate](https://codeclimate.com/github/ifad/colore/badges/gpa.svg)](https://codeclimate.com/github/ifad/colore)

![Color Wheel](http://upload.wikimedia.org/wikipedia/commons/thumb/3/38/BYR_color_wheel.svg/480px-BYR_color_wheel.svg.png)

Colore is a document storage, versioning and conversion system. Documents are
stored on the filesystem, in a defined directory structure. Access to these
documents is via API. Colore is intended to sit behind a proxying web server
(e.g. Nginx), which can be used to directly access the documents, rather than
putting that access load on Colore itself.

## Authentication

There is no authentication baked into Colore itself. The expectation is that
this will be performed by the proxying web server.

## Directory structure

All Colore documents are stored in subdirectories under a single *storage*
directory, which is defined in configuration. Beneath the storage directory
documents are divided up by application - the expectation is that each
application will keep to its own namespace when working on documents, though
this is not enforced.

Under the application directory, documents are organised by `doc_id`, which is
defined by the application when storing documents. The overall directory
structure is like this:

    {storage directory} - {app} - {doc_id} ┬─ metadata.json
                                           ├─ title
                                           ├─ current → v002
                                           ├─ v001 ─┬─ foo.docx
                                           │        ├─ foo.pdf
                                           │        └─ _author.txt
                                           └─ v002 ─┬─ foo.docx
                                                    ├─ foo.jpg
                                                    └─ _author.txt


As you can see, this document has two versions of *foo.docx*. The first
version was converted to PDF and the second to an image. The current version
is *v002* - defined by the symlink *current*. The *metadata.json* file is a
JSON description of the directory structure. The file *_author.txt* holds
the name of the author of the document version.

API Definition
--------------

This is a simple JSON API. Requests are submitted generally as POSTS with form
data. The response format depends on the request made, but are generally
content type JSON.

Error responses are always JSON, and have this format:

```json
{
  "status": ERROR_CODE,
  "description": "A description of the error"
}
```

### Create document

This method will create a new document, then perform the actions of Update
document, below.

    PUT /document/:app/:doc_id/:filename

Params: (suggest using multipart/form-data)

* `file`         - the uploaded file object (e.g. from `<input type="file"/>`)
* `title`        - a description of the document *(optional)*
* `author`       - the document author *(optional)*
* `actions`      - an array of conversions to perform *(optional)*
* `callback_url` - a URL that Colore will call when the conversions are completed *(optional)*

#### Example:

Request:

    PUT /document/myapp/12345/foo.docx
      title=A test document
      author=mr.spliffy
      actions[]=pdf
      actions[]=oo


Response:

```json
{
  "status": 201,
  "description": "Document stored",
  "app": "mapp",
  "doc_id": "12345",
  "path": "/documents/myapp/12345/current/foo.docx"
}
```

### Update document

This method will create a new version of an existing document and store the
supplied file. If conversion actions are specified, these conversions will be
scheduled to be performed asynchronously, and will `POST` to the optional
`callback_url` when each is completed.

    POST /document/:app/:doc_id/:filename

Params *(suggest using `multipart/form-data`)*:

* `file`         - the uploaded file object *(e.g. from `<input type="file"/>`)*
* `author`       - the new file's author *(optional)*
* `actions`      - an array of conversions to perform *(optional)*
* `callback_url` - a URL that Colore will call when the conversions are completed *(optional)*

#### Example:

Request:

    POST /document/myapp/12345/foo.docx
    author=mr.spliffy
    actions[]=pdf
    actions[]=ooffice

Response:

```json
{
  "status": 201,
  "description": "Document stored",
  "app": "myapp",
  "doc_id": "12345",
  "path": "/documents/myapp/12345/current/foo.docx"
}
```

### Update document title

This method will change the document's title.

    POST /document/:app/:doc_id/title/:title

The `:title` must be URL-encoded.

#### Example:

Request:

    POST /document/myapp/12345/title/This%20is%20a%20new%20title

Response:

```json
{
  "status": 200,
  "description": "Title changed",
}
```

### Request new conversion

This method will request a new conversion be performed on a document version.
Colore will do this asynchronously and will POST to the optional callback_url
when completed.

    POST /document/:app/:doc_id/:version/:filename/:action

Params *(suggest using multipart/form-data)*:

* `version`      - the version to convert *(e.g. `v001`, or `current`)*
* `action`       - the conversion to perform *(e.g. pdf)*
* `callback_url` - a URL that Colore will call when the conversions are completed *(optional)*

#### Example:

Request:

    POST /document/myapp/12345/current/foo.docx/pdf

Response:

```json
{
  "status": 202,
  "description": "Conversion initiated"
}
```

### Delete document

This method will completely delete a document.

    DELETE /document/:app/:doc_id

There are no parameters.

#### Example:

Request:

    DELETE /document/myapp/12345

Response:

```json
{
  "status": 200,
  "description": "Document deleted"
}
```

### Delete document version

This method will delete just one version of a document. It is not possible to delete the current version.

    DELETE /document/:app/:doc_id/:version

#### Example:

Request:

    DELETE /document/myapp/12345/v001

Response:

```json
{
  "status": 200,
  "description": "Document version deleted"
}
```

### Get file

This method will retrieve a document file, returning it as the response body.
This method is really only meant for testing purposes, and it is disabled if
the `RACK_ENV` variable is set to `production`. In a live environment this is
expected to be performed by the proxying web server. See the [example nginx
configuration](https://github.com/ifad/colore/blob/master/nginx/colore.nginx.conf)
for details.

    GET /document/:app/:doc_id/:version/:filename

#### Example:

Request:

    GET /document/myapp/12345/v001/foo.pdf

Response:

    Content-Type: application/pdf; charset=binary

    ... document body ...

### Get document info

This method will return a JSON object detailing the document contents.

    GET /document/:app/:doc_id

#### Example:

Request:

    GET /document/myapp/12345

Response:

```json
{
  "status": 200,
  "description": "Information retrieved",
  "app": "myapp",
  "doc_id": "12345",
  "title": "Sample document",
  "current_version": "v002",
  "versions": {
    "v001": {
      "docx": {
        "content_type": "application/msword",
        "filename": "foo.docx",
        "path": "/document/myapp/12345/v001/foo.docx",
        "author": "mrspliffy"
        "created_at": ""2015-04-13 13:26:41 +0100"
      },
      "pdf": {
        "content_type": "application/pdf; charset=binary",
        "filename": "foo.pdf",
        "path": "/document/myapp/12345/v001/foo.pdf",
        "author": "mrspliffy"
        "created_at": ""2015-04-13 13:26:41 +0100"
      }
    },
    "v002": {
      "docx": {
        "content_type": "application/msword",
        "filename": "foo.docx",
        "path": "/document/myapp/12345/v001/foo.docx",
        "author": "mrspliffy"
        "created_at": ""2015-04-13 13:26:41 +0100"
      },
      "txt": {
        "content_type": "text/plain; charset=us-ascii",
        "filename": "foo.txt",
        "path": "/document/myapp/12345/v001/foo.txt",
        "author": "mrspliffy"
        "created_at": ""2015-04-13 13:26:41 +0100"
      }
    }
  }
}
```

### Convert document

This is a foreground document conversion request. The converted document will
be returned as the response body.

    POST /convert

Params *(suggest using `multipart/form-data`)*:

* `file`      - the file to convert
* `action`    - the conversion to perform *(e.g. `pdf`)*
* `language`  - the file language *(defaults to `en`)*

#### Example:

    POST /convert
      file=... foo.docx ...
      action=pdf
      language=en

Response:

      Content-Type: application/pdf; charset=binary

      ... PDF document body ...

## Callbacks

When a document conversion is completed, an attempt will be made to POST a
callback to the URL specified when the conversion was attempted. The callback
will be a normal form post, sending these values:

* `status`      - the result of the conversion, `200` for success, `400+` for failure
* `description` - the outcome of the conversion, e.g. *Document converted*
* `app`         - the application name
* `doc_id`      - the ID of the document
* `version`     - the version of the document that was converted
* `action`      - the conversion action performed
* `path`        - a path to the converted file. You will have to tack the Colore URL base onto this

## Depedendencies

Colore expects the following commands to be available in it's PATH:

* `libreoffice` - From LibreOffice, `libreoffice` on Debian.
* `convert` - From ImageMagick, `imagemagick` on Debian.
* `tika` - From Apache Tika, `libtika-java` on Debian.

## Tika notes

If your distribution does not provide a wrapper script for the `tika-app`, you
can place the following one in `/usr/local/bin`:

```sh
#!/bin/sh

ARGS="$@"

[ $# -eq 0 ] && ARGS='--help'

exec java -jar /usr/share/java/tika-app.jar $ARGS
```

## Contributing

Want to contribute? Great!

1. Fork it.
2. Create a branch (`git checkout -b my_great_patch`)
3. Commit your changes (`git commit -am "Added Awesome Stuff"`)
4. Push to the branch (`git push origin my_great_patch`)
5. Open a [Pull Request](https://github.com/ifad/colore/pulls)
6. Enjoy

## Authors

* Joe Blackman -- <j.blackman@ifad.org>

## License

MIT
