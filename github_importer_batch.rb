# coding: utf-8
require 'set'
require 'octokit'
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
# Scan all issue in a repository and extract the information necessary to
# detect hotspots. If you provide authentication information in a
# ~/.netrc file, it will be used, but it is not necessary for public projects.
class BatchImporter

  def initialize
    # TODO: Configuration that SHOULD be supplied on the command line
    @repo = 'nikomatsakis/dummy'
    @authenticate = false
    @max_pages = 3
    @issue_log = {}
    # If you have a ~/.netrc file, use it (not necessary for public projects)
    @client = Octokit::Client.new(:netrc => true)
  end

  def run
    repo = @repo
    max_pages = @max_pages

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
