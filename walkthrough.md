# walkthrough / prep
## glossary
- opentelemetry
    + opentelemetry is specification representing datadogs metrics collection libraries and utilities that they open-sourced. the bits we really need are analagous to dd-trace
- trace
    + a generic term for representing the time a program spent doing some unit of execution. a distributed trace is the same thing, but measuring spans of time across multiple programs.
- flask
    + a small python library that makes it nicer to write webserver-style programs.
- tilt
    + a dev utility for k8s or docker-compose that enables faster development by syncing then hot-reloading containers when file change in the host os.
- docker 
    + a container runtime, builder, and container-management-api. a docker image is a flat file representing a complete filesystem. the docker daemon can be issued commands. the most important commands tell it to take that flat image file and execute some command with it mounted via a chroot, so that the command views itself as running alone in a controlled filesystem.
- docker-compose
    + a tool to make interacting with docker nicer. you define the various bits of configuration in a yaml file that youd normally need to include as cli flags when calling docker-run. tilt.dev is using this compose file to define its interactions with docker
- pip
    + python dependency manager, its how were installing flask and the opentelemetry packages
- jinja
    + templating language used by flask. this is for including values from the program in html. if you go to localhost:5000/11215, you will receive an html page with some values injected from the dataset, instead of a json blob like you'd get from localhost:5000/zips/11215
- instrumentation
    + generic context-jargon. references a technique where you proxy the various methods and functions of a program so that you can measure how much time was spent on each. the output of instrumenting a program is traces.

## important files
- Dockerfile
    + the dockerfile tells docker how to build your container image (see docker, above). Later i'll go through line-by-line and explain what each line is doing. for now though all you need to know is that a dockerfile is a series of commands that are issued to the docker image builder that tell it how to put that filesystem together. the output of `docker build .` is a flat docker image file.
- docker-compose.yml
    + this file defines the various configuration options that youd give docker if you were running it directly via the command line. if you were to run this without tilt.dev, you could do `docker-compose up` to start the container. 
- entrypoint.sh
    + the last line in the dockerfile is an ENTRYPOINT command. this tells docker that this container needs to execute entrypoint.sh, which is a bit of bash. it sets a few important environment variables, then starts our flask server via opentelemetry-instrument
- entry.py
    + the above file ends by executing this file. this is our python code that responds to http requests

## deep-dive on docker-compose.yml
- services
    + services is the top level unit of organization for docker-compose. each service represents a container you want to run, and all the configuration/metadata required for container operation. we only have the 1 service here, zips.
- image
    + this tells docker which image it should be using. docker maintains a registry of container images on your computer. these are the output from `docker build`. images can be "tagged", which is exactly what it sounds like. this value is a docker container image tag. if docker doesn't have an image with this tag in its container registry, it will attempt to build one if the `build` stanza is present for this service.
- init
    + this tells docker to wrap our entrypoint in an init script (tini, in this case). an init script is traditionally pid 1 in unix systems. without this, there is nothing to reap zombie child processes, and signals won't be forwarded from the host os to the program we're running inside the container. this means ctrl-c wouldn't be able to stop the container, which is extremely annoying.
- environment
    + these values are passed into the container as environment variables, this is how we are passing in the lightstep service and token values so we dont have to include those sensitive details in the git repository
- build
    + this tells docker-compose how to build the container image if it doesnt have an image tagged zips:latest locally.
- ports
    + here we can tell docker which ports from the host os should be forwarded to the container. we use 5000:5000 so that you can access port 5000 in the browser and its forwarded to port 5000 inside of the container, which flask is listening on.

## deep-dive on Dockerfile
This is arguably the most important bit of this repo. The dockerfile is a series of commands that the docker image builder is using to generate the container image. I am going to type out what each line is doing, because this really is the most important part of this thing:

- `FROM ubuntu:18.04`
    + the FROM statement tells docker that we want to use a container image tagged ubuntu:18.04 as the "base" of the container image we're generating. Basically, we're starting out with a really stripped-down linux filesystem.
- `RUN apt-get update && apt-get install -yyq python3 python3-pip`
    + this first updates the images ubuntu package registry, then installs python3 and pip.
- `COPY requirements.txt /zips/requirements.txt`
    + requirements.txt is a common pattern to annotate which dependencies and version a python program relies on to operate. usually youd want all of your dependencies in here, but dependency hell is real, so subsequent steps are going to be installing some more packages directly.
- `RUN pip3 install --upgrade pip`
    + we're telling pip to upgrade itself, some of the packages we're about to install require some newer pip features.
- `RUN pip3 install --no-cache-dir -r /zips/requirements.txt`
    + install the deps in requirements.txt
- `RUN pip3 install --use-feature=2020-resolver opentelemetry-distro==0.21b0 opentelemetry-launcher opentelemetry-instrumentation-flask`
    + this was the really annoying bit. we're installing 3 opentelemetry packages here: the distro, the launcher, and the flask automatic instrumentation. we need to use the 0.21b0 version of the distro because its the only one that supports flask2. we have to manually install the flask instrumentation, which a subsequent command *should* have installed for us, but doesn't for some reason. I don't know what the launcher package is but it was in some blog posts and this didn't work without it.
- `COPY zips.json /zips`
    + copy the zips.json file that has all them zips in it
- `COPY templates /zips/templates`
    + copies jinja templates into the container image
- `COPY entry.py /zips`
    + copy the actual python code into the container image. this is the business logic of the api that serves the http routes
- `COPY entrypoint.sh /zips`
    + copies in the entrypoint shell script we want docker to execute
- `RUN opentelemetry-bootstrap --action=install`
    + this is supposed to automatically install all the auto instrumentation libraries for installed packages. It does that for everything except for flask, which is the only one we actually care about.
- `ENTRYPOINT ["/zips/entrypoint.sh"]`
    + finally, this line tells docker that when you run this container, the process to spawn. our entrypoint sets some important environment variables and then calls `exec opentelemetry-instrument python3 /zips/entry.py`, which runs our flask server with the open-telemetry automatic instrumentation

## explanation of opentelemetry-instrument
This command is installed by one of the opentelemetry pip packages. You basically call it and tell it what command to run, (in our case that is `python3 /zips/entry.py`). It then figures out what the program is using (in our case flask, amongst other stuff) and sets up the instrumentation of all the flask methods/functions that we care about tracing. Then it runs our command normally.

## explanation of entry.py
This is the actual api definition.
- It starts with importing some modules from flask and stdlib.
- Then it does some flask boilerplate, this is what gives us the nice routing syntax.
- next, we're opening the zips.json file and converting it to a python dict that we use to return zipcode metadata. 
- the next 3 blocks tell flask which logic to execute when it receives http requests. the function under each @app.route decorator returns the data that route needs. you'll notice that `/<zip>` and `/zips/<zip>` handlers are being passed an input (zip). that input is being supplied by flask and is coming out of the URI path from the http request. ie: if you queried `localhost:5000/zips/11215`, the value would be 11215
- the last bit is some boilerplate that tells us to start the flask webserver if the programs name is `__main__`, and start it listening for requests on port 5000 across all network interfaces. we need this, otherwise the app only runs if you were to call it via `flask run`, which i don't like.

## program flow
Just as a reference/map, i'm going to outline the conceptual flow of how the server is being executed:

- init value from docker-compose.yml tells docker to run tini, which will itself call the ENTRYPOINT of the container image
- docker ENTRYPOINT from dockerfile points to entrypoint.sh
- entrypoint.sh points to opentelemetry-instrument with a command, which is:
- python3 /zips/entry.py our program! the instrumentation from above generates traces for us. the program above parses the traces and forwards them to lightstep

Thats it. bug me with any questions/concerns/etc. i don't think i missed anything important, but im also wrong a lot.
