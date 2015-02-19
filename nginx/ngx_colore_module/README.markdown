Name
====

**colore_set_subdirectory** - Colore-specific module to derive the storage subdirectory for Colore documents, to allow Nginx to serve the documents directly, rather than via the Colore application. This saves time and puts less load on Colore.

*This module is not distributed with the Nginx source.* See [the installation instructions](#installation).

Table of Contents
=================
* [Version](#version)
* [Synopsis](#synopsis)
* [Description](#description)
* [Directives](#directives)
    * [set_colore_subdir](#set_colore_subdir)
* [Caveats](#caveats)
* [Installation](#installation)
* [Compatibility](#compatibility)
* [Changes](#changes)
* [Author](#author)
* [Copyright and Licence](#copyright--licence)


Version
=======

v1.0.0

Synopsis
========

```nginx

 location ~ /document/.*?/(?<doc_id>)/.*$ {
     set_colore_subdir $subdir $doc_id 2;
     rewrite ^/document/(.*?)/(.*)$  /storage/$1/$subdir/$2 last;
     ... further Colore configuration ...
 }

 location /storage {
     root path_to_storage_directory;
 }
```

Description
===========

This module is designed to integrate Colore with Nginx, so that Nginx can serve document requests directly, rather than passing up to the Colore application.
By doing this, we reduce the load on Colore - the expectation being of course that document requests will far outnumber document modifications.

Colore writes documents to the storage directory using this subdirectory structure:

    {storage-directory} - {app} - {subdir} - {doc_id} - {version} - {filename}
    
    for example:
    
    {storage-directory}/myapp/82/12345/v001/bob.pdf

So, given a URL: <code>/document/myapp/12345/v001/bob.pdf</code>, the only part that has to be derived is the <code>{subdir}</code>. This is the first N
characters of a MD5 sum of the doc_id. The purpose of having a subdirectory is to allow the storage to scale to hundreds of thousands of documents without
running into large directory syndrome, where the bigger a directory is the longer it takes to search it.

This module provides the <code>set_colore_subdir</code> directive to derive this subdirectory. This directive can be mixed freely with other location and rewrite directives.

Thanks to the [Nginx Devel Kit](https://github.com/simpl/ngx_devel_kit) for making this module easy!

[Back to TOC](#table-of-contents)

Directives
==========

[Back to TOC](#table-of-contents)

set_colore_subdir
-----------------
**syntax:** *set_colore_subdir $dst &lt;doc_id&gt; &lt;length&gt;

**default:** *no*

**context:** *location, location if*

**phase:** *rewrite*

Calculate a MD5 sum (hex) of the argument `<doc_id>`, take the first `<length>` characters and assign it to $dst.

In the following example.

```nginx
  set $doc_id "12345";
  set_colore_subdir $dst $doc_id 2;
```

The variable $dst will take the value "82" (the MD5 hash of "12345" is "827ccb0eea8a706c4c34a16891f84e7b").

[Back to TOC](#table-of-contents)

Caveats
=======

[Back to TOC](#table-of-contents)

There are no caveats. Use it and laugh.

Installation
============

[Back to TOC](#table-of-contents)

Grab the nginx source code from [nginx.org](http://nginx.org/), and also the Nginx Devel Kit [Github repository](https://github.com/simpl/ngx_devel_kit)
and then build the Nginx source with this module:

```bash

 wget 'http://nginx.org/download/nginx-1.7.7.tar.gz'
 tar -xzvf nginx-1.7.7.tar.gz
 cd nginx-1.7.7/

 # Here we assume you would install your nginx under /opt/nginx/.
 ./configure --prefix=/opt/nginx \
     --with-http_ssl_module \
     --add-module=/path/to/ngx_devel_kit \
     --add-module=/path/to/ngx_colore_module

 make -j2
 make install
```

Compatibility
=============

The following versions of Nginx should work with this module:

* **1.7.x**
* **1.6.x**                      (last tested: 1.6.2)

[Back to TOC](#table-of-contents)

Changes
=======

[Back to TOC](#table-of-contents)

Author
======

Joe Blackman *&lt;j.blackman@ifad.org&gt;*, IFAD

[Back to TOC](#table-of-contents)

Copyright & Licence
===================

Copyright (C) 2015 IFAD

This module is licenced under the terms of the MIT licence.

[Back to TOC](#table-of-contents)
