# README

* Ruby version
This repo was built on `ruby 3.4.9`

* Database creation
`rails db:create`

* How to run the test suite
Use `rspec` to run all tests in the repo, or use `rspec [relative_path_to_test_file]` for specific files to test

* Services (job queues, cache servers, search engines, etc.)
You can find the primary endpoint at `/forecasts`. There is a UI to include an address you can use for finding forecast information, or you can call `forecast?address=[your_address_here]`.

Note that you must add a GEOCODE_API_KEY to your `.env` file. You can get a key from https://geocode.maps.co/. An example was added to this repo but you will need to use your own for the service to work. Note you can add this to a `.env.local` file in order to ensure you don't accidentally commit it

* Deployment instructions
Use `bundle install` at the root of this repo to install all necessary gems.
Run using `rails server` in the root of this repo to start the server.
Access at http://localhost:3000
