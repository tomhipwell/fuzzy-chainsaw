# HTTP-HTTPS

Runs nginx and redirects all http requests to some url to https.

## Getting started

Build the image and then run the container:

```shell
docker image build -t http-https .
docker run -p 8080:8080 -d http-https:latest
```

The nginx configuration is bundled in the same subdirectory and is added automatically during the image build. The above run command forwards requests on port 8080 on localhost to the container, thus, to test out the container you can do the following:

```shell
curl http://localhost:8080 -I -H "Host: example.com"
```

And you should get a nice HTTPS redirect:

```shell
HTTP/1.1 301 Moved Permanently
Server: nginx/1.17.3
Date: Sun, 01 Sep 2019 08:02:52 GMT
Content-Type: text/html
Content-Length: 169
Connection: keep-alive
Location: https://example.com
```

## Manually deploying the image during test

Once built, you can manually deploy your image to test it out.

Firstly, configure docker to use gcloud as a credential helper:

```shell
gcloud auth configure-docker
```

Then tag your docker image with the container registry name, for example:

```shell
docker tag http-https eu.gcr.io/"$PROJECT"/http-https
```

Push the tagged image to the container registry:

```shell
docker push eu.gcr.io/"$PROJECT"/http-https
```