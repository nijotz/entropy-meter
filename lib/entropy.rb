require 'json'
require 'open-uri'
require File.expand_path('../entropy_settings.rb', __FILE__)


####
# How many headlines are about chaos in the world?
####
def get_headline_entropy()
    ####
    # Get news headlines from the defined service
    ####
    news = JSON.load( open($news_url) {|io| io.read} )
    articles = $get_articles.call(news)
    titles = $get_titles.call(articles)

    ####
    # Get headline words, ratings, etc.
    ####
    title_data = []
    for title in titles do
        data = {}
        data['title'] = title
        # Lower case the title words and remove punctuation and neutral words
        data['title_words'] = title.downcase().gsub(/'s/,'').gsub(/[^a-z\s]/, '').split(' ').select { |x| not $words['neutral'].include?(x) }
        data['bad'] = []
        data['good'] = []
        data['unknown'] = []

        # Add words to list depending on what list they are in.
        for word in data['title_words'] do
            if $words['good'].include?(word)
                data['good'].push(word)
            elsif $words['bad'].include?(word)
                data['bad'].push(word)
            else
                data['unknown'].push(word)
            end
        end

        # Score title from -1 to 1 depending on how many good and bad words there are.
        data['rating'] = (data['bad'].length - data['good'].length()).to_f / data['unknown'].length()
        title_data.push(data)
    end

    ####
    # Rate headlines
    ####

    # Get a number from 0 to 1 of ratio of bad headlines to total headlines.  A
    # bad headline is one with a rating (calculated above) greater than 0.
    bad_titles = title_data.select{ |title| title['rating'] > 0 }
    bad_titles_num = bad_titles.length()
    good_titles = title_data.select{ |title| title['rating'] < 0 }
    good_titles_num = good_titles.length()
    unknown_titles = title_data.select{ |title| title['rating'] == 0 }
    unknown_titles_num = unknown_titles.length()
    total_titles_num = title_data.length()
    title_rating = ((bad_titles_num - good_titles_num).to_f / (2 * total_titles_num)) + 0.5

    ####
    # Score all the words in the headlines
    ####

    # Gather words from the headlines based on type
    words = {}
    for type in ['bad', 'good', 'unknown'] do
        words[type] = title_data.map{ |title| title[type] }.flatten()
    end

    # Score from 0 to 1 the words in the headlines.  0 being every single word
    # was good, and 1 being every single word was bad.
    bad_words_num = words['bad'].length()
    good_words_num = words['good'].length()
    unknown_words_num = words['unknown'].length()
    total_words_num = bad_words_num + good_words_num + unknown_words_num
    word_rating = ((bad_words_num - good_words_num).to_f / (2 * total_words_num)) + 0.5

    ####
    # Log stats
    ####
    puts 'Bad word count: %s' % [bad_words_num]
    puts 'Bad words: %s' % [words['bad']]
    puts 'Good word count: %s' % [good_words_num]
    puts 'Good words: %s' % [words['good']]
    puts 'Unknown word count: %s' % [unknown_words_num]
    puts 'Unknown words: %s' % [words['unknown']]
    puts 'Word rating: %f' % [word_rating]
    puts 'Bad headlines: %p' % [bad_titles.map{|t| t['title']}]
    puts 'Good headlines: %p' % [good_titles.map{|t| t['title']}]
    puts 'Unknown headlines: %p' % [unknown_titles.map{|t| t['title']}]
    puts 'Title rating: %f' % [title_rating]

    ####
    # Return entropy of headlines, 0 to 1, by avging words and titles
    ####
    return (word_rating + title_rating) / 2.0
end


####
# How many JIRA tickets has management opened wanting demos setup?
####
def get_jira_ticket_entropy()
    ####
    # How many tickets have been created in the time period?
    ####
    url = $jira_all_url % { :time => $jira_time_period }
    response = open(URI.encode(url), :http_basic_authentication=>$jira_auth)
    tickets = JSON.load(response.read())
    total = tickets['total']

    ####
    # How many tickets have been created by bad people in the time period?
    ####
    bad_user_total = 0
    for user in $bad_jira_users do
        url = $jira_user_url % { :time => $jira_time_period, :user => user }
        response = open(URI.encode(url), :http_basic_authentication=>$jira_auth)
        tickets = JSON.load(response.read())
        bad_user_total += tickets['total']
    end

    ####
    # How many tickets have been created with bad words in the time period?
    ####
    bad_word_total = 0
    for word in $bad_jira_words do
        url = $jira_word_url % { :time => $jira_time_period, :word => word }
        response = open(URI.encode(url), :http_basic_authentication=>$jira_auth)
        tickets = JSON.load(response.read())
        bad_word_total += tickets['total']
    end

    ratio = (bad_user_total + bad_word_total) / total.to_f
    adj_ratio = Math.log(ratio * 3) / 5.0 + 1
    adj_ratio = [1, adj_ratio].min()
    adj_ratio = [0, adj_ratio].max()

    puts 'Total tickets: %d' % [total]
    puts 'Total bad user tickets: %d' % [bad_user_total]
    puts 'Total bad word tickets: %d' % [bad_word_total]
    puts 'Ratio: %f' % [ratio]
    puts 'Adjusted ratio: %f' % [adj_ratio]
    return adj_ratio
end


####
# Is there a release coming up?
####
def get_jira_release_entropy()
    response = open(URI.encode($jira_release_url), :http_basic_authentication=>$jira_auth)
    versions = JSON.load(response.read())
    for version in versions
        date_str = version['releaseDate']
        if !date_str
            next
        end
        date = Date.parse(date_str)
        now = Date.today()
        if date > now and date < now + $jira_release_days
            puts 'Release coming up: %s' % [version['name']]
            return 1
        end
    end
    puts 'No release coming up'
    return 0
end


def get_entropy()
    # The sources and their relative weights
    sources = {
        'get_headline_entropy' => 5,
        'get_jira_ticket_entropy' => 5,
        'get_jira_release_entropy' => 5,
    }
    entropy = 0
    total_weight = 0
    for source, weight in sources do
        source_entropy = send(source)
        puts '%s: %f' % [source, source_entropy]
        entropy += source_entropy * weight
        total_weight += weight
    end
    return ((entropy / total_weight) * 100).round()
end
