# plunker_www

This is the repository containing all the code to run the public-facing
portion of http://plnkr.co.

## Installation

To get started, clone this repository and install npm dependencies.

```
git clone https://github.com/filearts/plunker_www.git plunker_www
cd plunker_www
npm install
```

 > You may need to do the git clone with the --recursive flag to get the
 > submodules automatically populated.

Next, you must create config files for the environments in which you intend
to run Plunker. Normally, these would be `development` and `production`.

Create `config.development.json` and `config.production.json` with the
following structure:

```javascript
{
  "host": "hostname.com",
  "url": {
    "www": "http://hostname.com",
    "collab": "http://collab.hostname.com",
    "api": "http://api.hostname.com",
    "embed": "http://embed.hostname.com",
    "run": "http://run.hostname.com",
    "carbonadsH": "You can probably ignore this",
    "carbonadsV": "...and this"
  },
  "port": 8080,
  "oauth": {
    "github": {
      "id": "series_of_random_chars",
      "secret": "longer_series_of_random_chars"
    }
  }
}
```

If you just want to hack on the front-end (this repository), you can probably
just replace `hostname.com` with `plnkr.co` for each url except `www`.

For the `oauth` configuration, make sure you set up an application on github
(at https://github.com/settings/applications) and copy the `id` and `secret`
to the config files.

# Project structure

```
 -+ assets - Contains
  |-- css - Less / css styles
  |-- img - Images
  |-+ js 
    |-- apps - Entry point to the landing page and editor
    |-- controllers - Route handlers for different 'pages'
    |-- directives - Where most of the magic happens
    |-- panes - Modules that get automagically loaded as panes in the multi-pane
    |-- services - Code designed to be shared throughout the app
  |-- snippets - Snippets used by the ace editor for snippet expansion
  |-- vendor - Third-party libraries
 -+ middleware - Express middleware
 -+ views - jade views to render the initial markup for the landing/editor pages
```
