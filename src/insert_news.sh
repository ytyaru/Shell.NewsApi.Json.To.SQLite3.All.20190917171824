# $1: JSONテキスト, $2: JSONパス
json_extract() { sqlite3 :memory: 'select json_extract(readfile('\'"$1"\''), '\'"$2"\'');'; }
make_insert_stmt() { echo 'insert into news(published,url,title,body) values('\'"$1"\'','\'"$2"\'','\'"$3"\'','\'"$4"\'');'; }
# $1: NewsApiJSONパス
run() {
	local json_path="$1"
	local insert_sql="insert.sql"
	[ 'ok' != "`json_extract "$json_path" '$.status'`" ] && { echo 'エラー。JSONのstatusがokでない。: '"`json_extract "$json_path" '$.status'`" 1>&2; exit 1; }
	# SQLファイル内容を空にする（さもなくば連続使用時に前の分と合わせて追記されてしまう）
	: > "$insert_sql"
	local totalResults="`json_extract "$json_path" '$.totalResults'`"
	for idx in $(seq 0 $(expr $totalResults - 1)); do
		# JSONから項目を抽出する
		local published="`json_extract "$json_path" '$.articles['"$idx"'].publishedAt'`"
		local url="`json_extract "$json_path" '$.articles['"$idx"'].url'`"
		local title="`json_extract "$json_path" '$.articles['"$idx"'].title'`"
		local body="`json_extract "$json_path" '$.articles['"$idx"'].description'`" # とりあえずdescriptionで代用する
		# totalResultsが多すぎたとき各項目はNULL(空文字)になる。このときは終了する。JSONが正しい限り起こり得ない。
		[ -z "$title" ] && { echo "JSON不正。titleが空。totalResults:$totalResults,idx:$idx" 1>&2; break; }
		# insert文を作る
		make_insert_stmt "$published" "$url" "$title" "$body" >> "$insert_sql"
	done
	local db="news.db"
	sqlite3 "$db" < "$insert_sql"
}
run "$1"

