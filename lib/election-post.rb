require_dependency 'new_post_manager'
require_dependency 'post_creator'

class DiscourseElections::ElectionPost

  def self.build_poll(topic)
    nominations = topic.election_nominations

    return if nominations.length < 2

    poll_options = ''

    nominations.each do |n|
      # Nominee username is added as a placeholder. Without the username,
      # the 'content' of the token in discourse-markdown/poll is blank
      # which leads to the md5Hash being identical for each option.
      # the username placeholder is removed on the client before render.

      poll_options << "\n- #{n}"
      poll_options << build_nominee(topic, n)
    end

    content = "[poll type=regular]#{poll_options}\n[/poll]"

    update_election_post(topic.id, content)
  end

  def self.build_nominations(topic)
    content = ""
    nominations = topic.election_nominations

    if nominations.any?
      content << "<div class='title'>#{I18n.t('election.post.nominated')}</div>"

      content << "<div class='nomination-list'>"

      nominations.each do |n|
        content << build_nominee(topic, n)
      end

      content << "</div>"
    end

    message = topic.custom_fields['election_message']

    if message
      content << "\n\n #{message}"
    end

    update_election_post(topic.id, content, { skip_validations: true })
  end

  def self.build_nominee(topic, n)
    nomination_statements = topic.election_nomination_statements
    user = User.find_by(username: n)
    avatar_url = user.avatar_template_url.gsub("{size}", "50")

    html = "<div class='nomination'><span>"

    html << "<div class='nomination-user'>"
    html << "<div class='trigger-user-card' href='/u/#{n}' data-user-card='#{n}'>"
    html << "<img alt='' width='25' height='25' src='#{avatar_url}' class='avatar'>"
    html << "<a class='mention'>@#{n}</a>"
    html << "</div>"
    html << "</div>"

    html << "<div class='nomination-statement'>"
    statement = nomination_statements.find{ |s| s['username'] == n }
    if statement
      post = Post.find(statement['post_id'])
      html << "<a href='#{post.url}'>#{statement['excerpt']}</a>"
    end
    html << "</div>"

    html << "</span></div>"

    html
  end

  def self.update_election_post(topic_id, content, opts = {})
    election_post = Post.find_by(topic_id: topic_id, post_number: 1)
    revisor = PostRevisor.new(election_post, election_post.topic)

    opts.merge!({ skip_revision: true })

    result = revisor.revise!(election_post.user, { raw: content }, opts)

    election_post.publish_change_to_clients!(:revised, { reload_topic: true })
  end
end
