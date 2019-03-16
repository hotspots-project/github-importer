# github-importer

An importer for GitHub content into hotspot.

# Development Setup

The development setup follows https://developer.github.com/apps/quickstart-guides/setting-up-your-development-environment/


# Step 1: Smee

Install the smee client into your node environment

    npm install --global smee-client

Start a smee channel at https://smee.io/

Run the smee client with the URL from above

    smee --url [smee-url] --path /event_handler --port 3000


# Step 2: Register GitHub App

Register an app with github: https://github.com/settings/apps

Use the smee-url for the Homepage and Webhook URLs. Set a Webhook secret.

For the first time, leave everything to the defaults, and select only install on this account. We can change these things later.

# Random notes

The permissions should probably be something like the following, but it doesn't seem to accept these when registering a new app.

Permissions:
- Issues: read-only
- Repository metadata: read-only
- Pull requests: read-only

Subscribe to events:
- Issues
- Issue comments
- Pull request
- Pull request review
- Pull request review comment
