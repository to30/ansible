# Ansibleのダイナミックインベントリ機能を使ってZabbixと連携する

ansible-playbook -i zabbix.py -l "production-app" test.yml

上記コマンドでZabbixのホストグループ"production-app"に属するサーバだけが実行対象になる
test.ymlで- hosts: sw1 と書くことで更に"production-app"に属したsw1だけと言ったことも出来る
課題：Zabbixから任意のグループに属したサーバ一覧を無条件に取ってきているのでこれをメンテ中のもののみ取得することが出来るようにしたい

こんな感じ


ホストグループIDを確認
curl -s -XGET -H 'Content-type:application/json-rpc' -d '{"jsonrpc": "2.0","method": "hostgroup.get","params": {"output": "extend","filter": {"name": ["production-app"]}},"auth": "認証トークン","id": 1}' http://ホスト名/zabbix/api_jsonrpc.php | jq '.'

ホストグループID(ここでは9)を指定して有効なホスト且つ保守中のリストを取得（何故か保守期間外の0だと何も引っかからなくなる）
curl -s -XGET -H 'Content-type:application/json-rpc' -d '{"jsonrpc": "2.0","method": "host.get","params": {"output": "extend","groupids": ["9"],"filter":{"status":"0"},"filter":{"maintenanceid":"1"}},"auth": "認証トークン","id": 1}' http://ホスト名/zabbix/api_jsonrpc.php | jq '.'

{
  "jsonrpc": "2.0",
  "result": [
    {
      "hostid": "10106",
      "proxy_hostid": "0",
      "host": "pa1",
      "status": "0",
      "disable_until": "0",
      "error": "",
      "available": "0",
      "errors_from": "0",
      "lastaccess": "0",
      "ipmi_authtype": "-1",
      "ipmi_privilege": "2",
      "ipmi_username": "",
      "ipmi_password": "",
      "ipmi_disable_until": "0",
      "ipmi_available": "0",
      "snmp_disable_until": "0",
      "snmp_available": "0",
      "maintenanceid": "1",
      "maintenance_status": "1",
      "maintenance_type": "0",
      "maintenance_from": "1470373920",
      "ipmi_errors_from": "0",
      "snmp_errors_from": "0",
      "ipmi_error": "",
      "snmp_error": "",
      "jmx_disable_until": "0",
      "jmx_available": "0",
      "jmx_errors_from": "0",
      "jmx_error": "",
      "name": "pa1",
      "flags": "0",
      "templateid": "0",
      "description": "",
      "tls_connect": "1",
      "tls_accept": "1",
      "tls_issuer": "",
      "tls_subject": "",
      "tls_psk_identity": "",
      "tls_psk": ""
    }
  ],
  "id": 1
}

後はホスト名だけ切り出して返せばOKの筈
明確に切り替えられるようにこっちはshellで作った方がよいかも

