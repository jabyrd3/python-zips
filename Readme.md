# python zips api
small flask api for fetching info about zip codes

# reqs
- docker
- docker-compose

# install
install [tilt.dev](https://docs.tilt.dev/install.html) for live dev.

# live dev
run `tilt up` from this directory

## what this means
whenever you change a file in this repos directory while tilt is running, the container will be updated in place. to see this in action, modify entry.py and then refresh the browser, you'll see your updated code represented immediately.

## working with tilt.dev
in the terminal with tilt running, press t to get a cli UI. you can expand the logs window by pressing x. pressing 3 will switch to container runtime logs. you can navigate which container logs you're looking at with j/k or up/down.

you can also go to locahost:10350 to get a browser GUI.

# routes
- localhost:5000/<zipcode> will return a jinja templated html page with zip and city. the jinja template here is in templates/root.html
- localhost:5000/zips/<zipcode> will return json with the full zip metadata dict
- localhost:5000/zips will (slowly) return the full zips dict
