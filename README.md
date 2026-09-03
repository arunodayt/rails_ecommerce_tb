# README
This is a Rails api only application with the following details:
Ruby version 3.4.9.
Rails version 8.1.3.
Database used is Postgres.
JWT auth has been setup using bcrypt (utilizing model User).
Authorization has been set using Pundit. Thre roles have been defined - Admin, Manager and Member.
Tests for some critical paths have been setup using minitest.
Background jobs are setup using the delayed_jobs backend, so no Redis server is required.

A very basic ecommerce app has been setup, which has customers, products and orders.

Steps to run the application:
Have the correct ruby and rails versions installed. Then run the following:

    bundle install
    rails db:create
    rails db:migrate
    rails db:seed

Then launch rails server the the following command:
    rails s