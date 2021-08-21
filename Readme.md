# python zips api
small api for fetching info about zip codes

# reqs
- docker
- docker-compose

# install
install [tilt.dev](https://docs.tilt.dev/install.html) for live dev.

# dev
run `tilt up` from this directory

# routes
- localhost:5000/<zipcode> will return a jinja templated html page with zip and city
- localhost:5000/zips/<zipcode> will return json with the full zip metadata dict
- localhost:5000/zips will return (slowly) the full zips dict
