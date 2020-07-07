# Panoptes ![Build Status](https://travis-ci.org/zooniverse/Panoptes.svg?branch=master) [![pullreminders](https://pullreminders.com/badge.svg)](https://pullreminders.com?ref=badge)

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

### Setup Docker and Docker Compose

* Docker
  * [OS X](https://docs.docker.com/installation/mac/) - Docker Machine
  * [Ubuntu](https://docs.docker.com/installation/ubuntulinux/) - Docker
  * [Windows](http://docs.docker.com/installation/windows/) - Boot2Docker

* [Docker Compose](https://docs.docker.com/compose/)

#### Usage

1. Clone the repository `git clone https://github.com/zooniverse/Panoptes`.

0. Install Docker from the appropriate link above.

0. `cd` into the cloned folder.

0. Run `docker-compose build` to build the containers Panoptes API container. You will need to re-run this command on any changes to `Dockerfile.dev`

0. Install the gem dependencies for the application
    * Run: `docker-compose run --rm panoptes bundle install`

0. Setup the configuration files via a rake task
    * Run: `docker-compose run --rm panoptes bundle exec rake configure:local`

0. Create and run the application containers with `docker-compose up`

0. If the above step reports a missing database error, kill the docker-compose process or open a new terminal window in the current directory and then run `docker-compose run --rm panoptes bundle exec rake db:setup` to setup the database. This command will launch a new Docker container, run the rake DB setup task, and then clean up the container.

0. To seed the development database with an Admin user and a Doorkeeper client application for API access run `docker-compose run --rm panoptes bundle exec rails runner db/dev_seed_data/dev_seed_data.rb`

0. Open up the application in your browser at http://localhost:3000

Once all the above steps complete you will have a working copy of the checked out code base. Keep your code up to date and rebuild the image on any code or configuration changes.

## Testing

There are multiple options for setting up a testing environment:

1. Run it entirely from within docker-compose:
    1. Run `docker-compose build` to build the panoptes container.
    0. Install the gem dependencies for the application
        * Run: `docker-compose run --rm panoptes bundle install`
    0. Create config files if you don't already have them, run `docker-compose run --rm -e RAILS_ENV=test panoptes bundle exec rake configure:local`
    0. To create the testing database, run `docker-compose run --rm -e RAILS_ENV=test panoptes bundle exec rake db:setup`
    0. Run the full spec suite `docker-compose run -T --rm -e RAILS_ENV=test panoptes bundle exec rspec` noting that running all tests is slow.
        * Use rspec focus keyword in your specs or specify the spec you want to run, e.g. `docker-compose run -T --rm -e RAILS_ENV=test panoptes rspec path/to/spec/file.rb`

0. Use docker to run a testing environment bash shell and run test commands .
    1. Run `docker-compose run --rm -e RAILS_ENV=test panoptes bash` to start the containers
    0. Run `bundle exec rspec` to run the full test suite

0. Use parts of docker-compose manually and wire them up manually to create a testing environment.
    1. Run `docker-compose run -d --name postgres --service-ports postgres` to start the postgres container
    0. Run `docker-compose run -T --rm -e RAILS_ENV=test panoptes bundle exec rspec` to run the full test suite

0. Assuming you have the correct Ruby environment already setup:
    1. Run `bundle install`
    0. Start the docker Postgres container by running `docker-compose run -d --name postgres --service-ports postgres` or run your own
    0. Create config files if you don't already have them, run `bundle exec rake configure:local`
    0. Create doorkeeper keys, run `bundle exec rake configure:doorkeeper_keys`
    0. Modify your `config/database.yml` test env to point to the running Postgres server, e.g. `host: localhost`
    0. Setup the testing database if you haven't already, by running `RAILS_ENV=test rake db:setup`
    0. Finally, run rspec with `RAILS_ENV=test rspec`

## Rails 5

Using the gem https://github.com/clio/ten_years_rails to help with the upgrade path
https://www.youtube.com/watch?v=6aCfc0DkSFo

#### Using docker-compose for env setup

`docker-compose -f docker-compose-rails-5.yml build`
`docker-compose -f docker-compose-rails-5.yml run --rm -e RAILS_ENV=test panoptes bash`

#### Install the gems via next

`next bundle install`

### check for incompatible gems for target rails verion

`bundle exec bundle_report compatibility --rails-version=5.0.7`

#### Run the specs

It's recommeded to enable spring for testing env
`unset DISABLE_SPRING`
run all specs for rails 5 gemfile
`BUNDLE_GEMFILE=Gemfile.next bundle exec rspec`

or fail fast
`BUNDLE_GEMFILE=Gemfile.next bundle exec rspec --fail-fast`

or with gaurd (recommended to enable spring)
`bundle exec guard -g rails5 --no-interactions`

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

Copyright 2014-2018 by the Zooniverse

Distributed under the Apache Public License v2. See LICENSE
