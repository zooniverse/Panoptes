# Panoptes ![Build Status](https://travis-ci.org/zooniverse/Panoptes.svg?branch=master)

The new Zooniverse API for supporting user-created projects.

## Documentation

The Panoptes public API is documented [here](http://docs.panoptes.apiary.io), using [apiary.io](http://apiary.io).

If you're interested in how Panoptes is implemented check out the [wiki](https://github.com/zooniverse/Panoptes/wiki) and the [Data Model Description](https://github.com/zooniverse/Panoptes/wiki/DataModel).

## Requirements

Since Panoptes uses Docker to manage its environment, the requirements listed below are also found in `docker-compose.yml`. The means by which a new Panoptes instance is created with Docker is located in the `Dockerfile`. If you plan on using Docker to manage Panoptes, skip ahead to Installation.

Panoptes is primarily developed against stable MRI, currently 2.4. If you're running MRI Ruby you'll need to have the Postgresql client libraries installed as well as have [Postgresql](http://postgresql.org) version 9.4 running.

* Ubuntu/Debian: `apt-get install libpq-dev`
* OS X (with [homebrew](http://homebrew.io)): `brew install postgresql`

Optionally, you can also run the following:

* [Cellect Server](https://github.com/zooniverse/Cellect) version > 0.1.0
* [Redis](http://redis.io) version > 2.8.19

## Installation

We only support running Panoptes via Docker and Docker Compose. If you'd like to run it outside a container, see the above Requirements sections to get started.

It's possible to run Panoptes only having to install the `fig_rake` gem. Alternatives to various rake tasks are presented.

### Setup Docker and Docker Compose

* Docker
  * [OS X](https://docs.docker.com/installation/mac/) - Docker Machine
  * [Ubuntu](https://docs.docker.com/installation/ubuntulinux/) - Docker
  * [Windows](http://docs.docker.com/installation/windows/) - Boot2Docker

* [Docker Compose](https://docs.docker.com/compose/)

#### Usage

0. Clone the repository `git clone https://github.com/zooniverse/Panoptes`.

0. `cd` into the cloned folder.

0. Setup the configuration files via a rake task
  + Run: `rake configure:local`

  Or manually copy the example configuration files and setup the doorkeeper keys.
  + Run: `find config/*.yml.hudson -exec bash -c 'for x; do x=${x#./}; cp -i "$x" "${x/.hudson/}"; done' _ {} +`
  + Run: `rake configure:doorkeeper_keys`

0. Install Docker from the appropriate link above.

0.  + **If you have an existing Panoptes Docker container, or if your Gemfile or Ruby version has changed,** run `docker-compose build` to rebuild the containers.
    + Otherwise, create and run the application containers by running `docker-compose up`

0. After step 5 finishes, open a new terminal and run `docker-compose run --rm --entrypoint=rake panoptes db:setup` to setup the database. This will launch a new Docker container, run the rake DB setup task, and then clean up the container.

0. To seed the development database with an Admin user and a Doorkeeper client application for API access run `docker-compose run --rm --entrypoint=rails panoptes runner db/fig_dev_seed_data/fig_dev_seed_data.rb`

0. Open up the application in your browser:
  + It should be running on http://localhost:3000
  + If it's not and you're on a Mac, run `docker ps`, and find the IP address where the `panoptes_panoptes` image is running. E.g.: 0.0.0.0:3000->3000/tcp means running on localhost at port 3000.

     ```
CONTAINER ID        IMAGE                         COMMAND                  CREATED             STATUS              PORTS                            NAMES
1f98164914be        panoptes_panoptes             "/bin/sh -c /rails_ap"   16 minutes ago      Up 16 minutes       80/tcp, **0.0.0.0:3000->3000/tcp**   panoptes_panoptes_1
     ```

This will get you a working copy of the checked out code base. Keep your code up to date and rebuild the image if needed!

## Testing

There are multiple options for setting up a testing environment:

0. Run it entirely from within docker-compose:

    0. Create config files if you don't already have them, run `docker-compose run --rm -e RAILS_ENV=test --entrypoint=rake panoptes configure:local`
    0. To create the testing database, run `docker-compose run --rm -e RAILS_ENV=test --entrypoint=rake panoptes db:setup`.
    0. Run the full spec suite `docker-compose run -T --rm -e RAILS_ENV=test --entrypoint=rspec panoptes`. Note: this will be slow. Use rspec focus set or specify the spec you want to run, e.g. `docker-compose run -T --rm -e RAILS_ENV=test --entrypoint="rspec path/to/spec/file.rb" panoptes`

0. Use parts of docker-compose manually and wire them up manually to create a testing environment.

    ```
    docker-compose run -d --name postgres --service-ports postgres
    docker-compose run -T --rm -e RAILS_ENV=test --entrypoint="bundle exec rspec" panoptes
    ```

0. Assuming you have a Ruby environment already setup:

    0. Run `bundle install`
    0. Start the docker Postgres container by running `docker-compose run -d --name postgres --service-ports postgres`
    0. Modify your `config/database.yml` test env to point to the running Postgres container, e.g. `host: localhost`
    0. Setup the testing database if you haven't already, by running `RAILS_ENV=test rake db:setup`
    0. Finally, run rspec with `RAILS_ENV=test rspec`

## Contributing

Thanks a bunch for wanting to help Zooniverse. Here are few quick guidelines to start working on our project:

0. Fork the Project on Github.
0. Clone the code and follow one of the above guides to setup a dev environment.
0. Create a new git branch and make your changes.
0. Make sure the tests still pass by running `bundle exec rspec`.
0. Add tests if you introduced new functionality.
0. Commit your changes. Try to make your commit message [informative](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html), but we're not sticklers about it. Do try to to add `Closes #issue` or `Fixes #issue` somewhere in your message if it's addressing a specific open issue.
0. Submit a Pull Request
0. Wait for feedback or a merge!

Your Pull Request will run on [travis-ci](https://travis-ci.org/zooniverse/Panoptes), and we'll probably wait for it to pass on MRI Ruby 2.4. For more information, [see the wiki](https://github.com/zooniverse/Panoptes/wiki/Contributing-to-Panoptes).

## License

Copyright 2014-2016 by the Zooniverse

Distributed under the Apache Public License v2. See LICENSE
