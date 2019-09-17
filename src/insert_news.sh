# $1: JSONテキスト, $2: JSONパス
json_extract() { sqlite3 :memory: 'select json_extract(readfile('\'"$1"\''), '\'"$2"\'');'; }
make_insert_stmt() { echo 'insert into news(published,url,title,body) values('\'"$1"\'','\'"$2"\'','\'"$3"\'','\'"$4"\'');'; }
# $1: NewsApiJSONパス
run() {
	local json_path="$1"
	local insert_sql="insert.sql"
	[ 'ok' != "`json_extract "$json_path" '$.status'`" ] && { echo 'エラー。JSONのstatusがokでない。: '"`json_extract "$json_path" '$.status'`" 1>&2; exit 1; }
	local totalResults="`json_extract "$json_path" '$.totalResults'`"
	for idx in $(seq 0 $(expr $totalResults - 1)); do
		# JSONから項目を抽出する
		local published="`json_extract "$json_path" '$.articles['"$idx"'].published'`"
		local url="`json_extract "$json_path" '$.articles['"$idx"'].url'`"
		local title="`json_extract "$json_path" '$.articles['"$idx"'].title'`"
		local body="`json_extract "$json_path" '$.articles['"$idx"'].description'`" # とりあえずdescriptionで代用する
		# insert文を作る
		make_insert_stmt "$published" "$url" "$title" "$body" >> "$insert_sql"
	done
	local db="news.db"
	sqlite3 "$db" < "$insert_sql"
}
run "$1"

