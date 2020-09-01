#!/usr/bin/env ruby
#
# use --help to get usage

require 'easy_shell'
require 'trollop'
require_relative '../config/environment'

BOTS = [
  'greenkeeperio-bot',
  'Core Network Bot'
].freeze

class RecipientError < StandardError; end

class GitImporter
  def import
    parse_opts
    repo = clone_repo
    commits = parse_log repo
    check_recipients commits
    send_awards commits
  end

  def parse_opts # rubocop:todo Metrics/CyclomaticComplexity
    @opts = Trollop.options do
      opt :github_repo, 'Github owner/repo, eg `ipfs/go-ipfs`', type: :string
      opt :project_id, 'Comakery project ID', type: :integer
      opt :history, 'Days of history (default: all)', type: :integer, default: nil
      opt :ethereum, 'Create awards on Ethereum blockchain', default: false
    end
    Trollop.die :github_repo, 'must be of the form `owner/repo`' if @opts[:github_repo]&.split('/')&.length != 2
    Trollop.die :project_id, 'required' unless @opts[:project_id] && @opts[:project_id] > 0
  end

  def clone_repo
    github_repo = @opts[:github_repo]
    local_repo = File.expand_path "../../tmp/import/github/#{github_repo}", __FILE__
    if Dir.exist?(File.join(local_repo, '.git'))
      run "cd #{local_repo} && git pull"
    else
      run "rm -rf #{local_repo}"
      run "mkdir -p #{local_repo}"
      origin = "https://github.com/#{github_repo}.git"
      run "git clone #{origin} #{local_repo}"
    end

    owner, repo = github_repo.split('/') # rubocop:todo Lint/UselessAssignment
    { local_repo: local_repo }
  end

  def parse_log(repo)
    git_log = %(git log
      --first-parent master
      --format='%H %x00 %an %x00 %ae %x00 %aI %x00 %s'
    )
    git_log += %( --since="#{@opts[:history] + 1} days ago") if @opts[:history].present?

    results = run "cd #{repo[:local_repo]} && #{git_log}", quiet: !$DEBUG
    logs = results.split("\n")

    commits = logs.map do |line| # rubocop:todo Lint/UselessAssignment
      elements = line.split(" \x00 ")
      git_hash, author_name, author_email, author_date, subject = elements
      {
        git_hash: git_hash,
        author_names: split_names(author_name),
        author_email: author_email,
        author_date: author_date,
        subject: subject
      }
    end
  end

  # handle pair programmers: split name on ' and ' or ' & ' or ', '
  def split_names(input)
    input.split(/,\s*|\s+and\s+|\s+&\s+/).reject do |name|
      BOTS.include?(name)
    end
  end

  def check_recipients(commits)
    project = Project.find @opts[:project_id] # rubocop:todo Lint/UselessAssignment
    author_names = commits.map { |commit| commit[:author_names] }.flatten.uniq.sort
    errors = []
    author_names.each do |author_name|
      slack_user_id(author_name)
    rescue RecipientError => e
      errors << e.message
    end
    raise RecipientError, errors.join("\n") if errors.present?
  end

  def slack_user_id(author_name) # rubocop:todo Metrics/CyclomaticComplexity
    project = Project.find @opts[:project_id]
    name_to_user_name = {
      'Adam Apollo' => 'adamapollo',
      'AdamApollo' => 'adamapollo',
      'aquabu' => 'noahthorp',
      'Duke Dorje' => 'duke',
      'Harlan T Wood' => 'harlan',
      'harlantwood' => 'harlan',
      'Jack Senechal' => 'jack',
      'Noah Thorp' => 'noahthorp'
    }
    unless @slack
      slack_team_id = project.slack_team_id
      auth = project.account.authentications.order(updated_at: :desc).where(slack_team_id: slack_team_id).first
      @slack ||= Comakery::Slack.new(auth.slack_token)
      @slack_user_name_to_slack_id = {}
      members = @slack.get_users[:members]
      members.each_with_object(@slack_user_name_to_slack_id) do |member, map|
        map[member.name] = member.id
      end
    end

    user_name = name_to_user_name[author_name]
    raise RecipientError, "Please add author '#{author_name}' to name_to_user_name map" unless user_name

    user_id = @slack_user_name_to_slack_id[user_name]
    raise RecipientError, "Slack user name '#{user_name}' not found in Slack team '#{project.slack_team_name}'" unless user_id

    user_id
  end

  def send_awards(commits) # rubocop:todo Metrics/CyclomaticComplexity
    awards = 0
    project = Project.find @opts[:project_id]
    award_type = project.award_types.order(:amount).first # lowest award
    commits.each do |commit|
      commit[:author_names].each do |author_name|
        proof_id = commit[:git_hash]
        next if project.awards.find_by(proof_id: proof_id)

        proof_link = "https://github.com/#{@opts[:github_repo]}/commit/#{commit[:git_hash]}"
        description = "Git commit to #{@opts[:github_repo]}: #{commit[:subject]}"

        result = AwardSlackUser.call(
          project: project,
          slack_user_id: slack_user_id(author_name),
          issuer: project.account,
          award_params: {
            award_type_id: award_type.id,
            description: description,
            proof_id: proof_id,
            proof_link: proof_link,
            created_at: commit[:author_date],
            updated_at: commit[:author_date]
          }
        )
        if result.success?
          award = result.award
          award.save!
          CreateEthereumAwards.call(award: award) if @opts[:ethereum]
          awards += 1
        else
          warn result.message
        end
      end
    end
    puts "Created #{awards} awards."
  end
end

GitImporter.new.import
