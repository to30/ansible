# Ansibleのダイナミックインベントリ機能を使ってZabbixと連携する

ansible-playbook -i zabbix.py -l "production-app" test.yml

上記コマンドでZabbixのホストグループ"production-app"に属するサーバだけが実行対象になる
test.ymlで- hosts: sw1 と書くことで更に"production-app"に属したsw1だけと言ったことも出来る

Zabbix APIのhost.getを叩いてるところで
"filter": {"maintenance_status": "1"}
と書いているのでZabbixでメンテナンス中になっていないサーバはインベントリリストとして表示されず、作業対象から除外される

Curlだとこんな感じ

ホストグループIDを確認
curl -s -XGET -H 'Content-type:application/json-rpc' -d '{"jsonrpc": "2.0","method": "hostgroup.get","params": {"output": "extend","filter": {"name": ["production-app"]}},"auth": "認証トークン","id": 1}' http://ホスト名/zabbix/api_jsonrpc.php | jq '.'

ホストグループID(ここでは9)を指定して有効なホスト且つ保守中のリストを取得（何故か保守期間外の0だと何も引っかからなくなる）
curl -s -XGET -H 'Content-type:application/json-rpc' -d '{"jsonrpc": "2.0","method": "host.get","params": {"output": "extend","groupids": ["9"],"filter":{"status":"0"},"filter":{"maintenanceid":"1"}},"auth": "認証トークン","id": 1}' http://ホスト名/zabbix/api_jsonrpc.php | jq '.'

