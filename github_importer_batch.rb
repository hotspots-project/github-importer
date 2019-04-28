# coding: utf-8
require 'set'
require 'octokit'
require 'dotenv/load' # Manages environment variables
require 'json'
require 'openssl'     # Verifies the webhook signature
require 'jwt'         # Authenticates a GitHub App
require 'time'        # Gets ISO 8601 representation of a Time object
require 'logger'      # Logs debug statements
require 'netrc'

###########################################################################
#
# Batch importer for hotspots
#
# This code will speed an entire repository and dump all of the events
# etc. For now it's just using an auth token.

# Expects that the private key in PEM format. Converts the newlines
PRIVATE_KEY = OpenSSL::PKey::RSA.new(ENV['GITHUB_PRIVATE_KEY'].gsub('\n', "\n"))

# Your registered app must have a secret set. The secret is used to verify
# that webhooks are sent by GitHub.
WEBHOOK_SECRET = ENV['GITHUB_WEBHOOK_SECRET']

# The GitHub App's identifier (type integer) set when registering an app.
APP_IDENTIFIER = ENV['GITHUB_APP_IDENTIFIER']

class BatchImporter
  def run
    @issue_log = {}
    @client = Octokit::Client.new(:netrc => true)

    # Configuration that SHOULD be supplied on the command line
    repo = 'nikomatsakis/dummy'
    max_pages = 3

    # Load first page of issues
    issues = @client.issues(repo)
    next_page = @client.last_response.rels[:next]

    # Walk page by page and get data from the issue; kind of inelegant
    # code.
    while max_pages > 0
      for issue in issues
        summarize_issue(repo, issue)
      end

      # Advance to next page (if any)
      if next_page
        puts "next page!"
        next_response = next_page.get
        next_page = next_response.rels[:next]
        issues = next_response.data
        max_pages -= 1
      else
        max_pages = 0
      end
    end
    puts @issue_log.to_json
  end

  def summarize_issue(repo, issue)
    issue_number = issue.number
    num_comments = issue.comments
    puts "#{repo}/##{issue_number} has #{num_comments} comment(s)"
    set = Set[]

    # To keep things fast, comment this out for now.
    # Also, is there a better way to get the number of participants?
    # Finally, perhaps we would like to make this part *lazy*, and only
    # fetch the number of participants if the number of commments is beyond
    # some threshold? I'm just concerned about rate limit.
    
    #for comment in @client.issue_comments(repo, issue_number)
    #  set.add(comment.user.id)
    #end

    number_of_participants = set.size
    @issue_log[issue_number] = {
      "num_comments":issue.comments,
      "num_participants":set.size,
    }
  end
end

BatchImporter.new.run
