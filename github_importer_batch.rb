# coding: utf-8
require "set"
require "octokit"
require "json"
require "openssl"     # Verifies the webhook signature
require "jwt"         # Authenticates a GitHub App
require "time"        # Gets ISO 8601 representation of a Time object
require "logger"      # Logs debug statements
require "netrc"

###########################################################################
#
# Import issues directly from GitHub
#
# Scan all issue in a repository and process them. If you provide authentication information in a
# ~/.netrc file, it will be used, but it is not necessary for public projects.
#
# The default processor extracts the information necessary to
# detect hotspots.
class RepoLiveBatchImporter
  def initialize(processor = nil)
    # TODO: Configuration that SHOULD be supplied on the command line
    @repo = "nikomatsakis/dummy"
    @max_pages = 3
    # If you have a ~/.netrc file, use it (not necessary for public projects)
    @client = Octokit::Client.new(:netrc => true)
    @processor = processor ? processor : RepoToHotspotProcessor.new
  end

  def run
    repo = @repo
    max_pages = @max_pages

    # Load first page of issues
    issues = @client.issues(repo)
    next_page = @client.last_response.rels[:next]

    # Walk page by page and get data from the issue; kind of inelegant
    # code.
    @processor.will_process(max_pages)
    while max_pages > 0
      for issue in issues
        @processor.process_issue(repo, issue)
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
    @processor.did_process
  end
end

##
# Extract the information necessary to compute hotspots from issues 
#
class RepoToHotspotProcessor
  def initialize
    @issue_log = {}
  end

  def will_process(max_number_of_pages)
  end

  # TODO: Extract this code to a separate module
  def process_issue(repo, issue)
    issue_number = issue.number
    num_comments = issue.comments
    title = issue.title
    puts "#{repo}/##{issue_number} [#{title}] has #{num_comments} comment(s)"
    set = Set[]

    # To keep things fast, comment this out for now.
    # Also, is there a better way to get the number of participants?
    # Finally, perhaps we would like to make this part *lazy*, and only
    # fetch the number of participants if the number of commments is beyond
    # some threshold? I'm just concerned about rate limit.

    #for comment in @client.issue_comments(repo, issue_number)
    #  set.add(comment.user.id)
    #end

    # puts issue.to_h
    number_of_participants = set.size
    @issue_log[issue_number] = {
      "num_comments": issue.comments,
      "num_participants": set.size,
    }
  end

  def did_process
    puts @issue_log.to_json
  end
end

# TODO: Implement a processor that stores the comments to a file/folder
class RepoToFileProcessor
  def initialize

  end

  def will_process(max_number_of_pages)
  end

  def process_issue(repo, issue)

  end

  def did_process
  end
end

##
# Import issues stored in files
#
# Read issues from files and process them
class RepoFileBatchImporter
  def initialize(processor = nil)
    # TODO: Configuration that SHOULD be supplied on the command line
    # @path = ?
    @processor = processor ? processor : RepoToHotspotProcessor.new
  end

  def run
    repo = @repo
    max_pages = @max_pages

    # Load first page of issues
    issues = @client.issues(repo)
    next_page = @client.last_response.rels[:next]

    # Walk page by page and get data from the issue; kind of inelegant
    # code.
    @processor.will_process(max_pages)
    while max_pages > 0
      for issue in issues
        @processor.process_issue(repo, issue)
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
    @processor.did_process
  end
end

RepoLiveBatchImporter.new.run
