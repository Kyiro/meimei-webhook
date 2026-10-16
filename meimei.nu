const SOURCE = "https://tiktok.com/@toletole_meimei"

let config = open config.toml
let webhook_url = $config.webhook_url

mut already_posted = try { open posted.txt | lines -s } catch { [] }

let new_posts = ^gallery-dl --no-input --no-download -o extractor.tiktok.tiktok-range=1-15 -j $"($SOURCE)/posts"
    | from json
    | each { |e| $e | last }
    | sort-by date
    | uniq-by id
    | where id not-in $already_posted

for post in $new_posts {
    try {
        send_to_discord $post
        $already_posted = ($already_posted | append $post.id)
    } catch { |e|
        print -e $e
        break
    }
    sleep 1sec
}

$already_posted | str join "\n" | save -f posted.txt

def send_to_discord [$post] {
    let avatar = $post | get -o author.avatarLarger
    let username = $post | get -o author.nickname | default "Meimei"
    let content = $"($SOURCE)/video/($post.id)" | str replace "tiktok" "tnktok"

    let webhook_body = {
        avatar_url: $avatar,
        username: $username,
        content: $content
    }

    http post -t application/json $webhook_url ($webhook_body | to json)
}