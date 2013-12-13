$news_url = 'http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&num=20&q=http%3A%2F%2Fnews.google.com%2Fnews%3Foutput%3Drss%26num%3D20'
$get_articles = lambda { |data| data['responseData']['feed']['entries'] }
$get_titles = lambda { |articles| articles.map { |article| article['title'].split('-')[0] } }
$words = {
    'good' => File.open(File.expand_path('../good_words.txt', __FILE__)).read().split(/\r?\n/),
    'bad' => File.open(File.expand_path('../bad_words.txt', __FILE__)).read().split(/\r?\n/),
    'neutral' => File.open(File.expand_path('../neutral_words.txt', __FILE__)).read().split(/\r?\n/)
}

$bad_jira_users = ['jdoe']
$bad_jira_words = ['demo', 'emergency']
$jira_release_url = 'https://jira.thetus.com/rest/api/2/project/SAV/versions'
$jira_user_url = 'https://jira.thetus.com/rest/api/2/search?jql=reporter=%{user}+and+createdDate>=-%{time}'
$jira_word_url = 'https://jira.thetus.com/rest/api/2/search?jql=text~"%{word}"+and+updatedDate>=-%{time}'
$jira_time_period = '48h'
$jira_release_days = 2
$jira_all_url = 'https://jira.thetus.com/rest/api/2/search?jql=createdDate>=-%{time}'
$jira_auth = ['jira-user', 'password']
