#!/bin/sh
#
# Zabbix を操作する関数をまとめたユーティリティスクリプト

URL='http://52.198.9.231/zabbix/api_jsonrpc.php'
ZABBIX_USER='Admin'
ZABBIX_PASSWORD='zabbix'

#######################################
# トークンを取得する
# https://www.zabbix.com/documentation/2.0/manual/appendix/api/user/login
# Returns:
#   TOKEN
#######################################
create_token() {
  PARAMS=$(cat << EOS
      {
          "jsonrpc": "2.0",
          "method": "user.login",
          "params": {
              "user": "${ZABBIX_USER}",
              "password": "${ZABBIX_PASSWORD}"
          },
          "id": 1
      }
EOS
  )

  curl -s -H 'Content-Type:application/json-rpc' \
       ${URL} \
       -d "${PARAMS}" | /usr/local/bin/jq -r '.result'
}

#######################################
# ホスト情報から hostid を取得する
# https://www.zabbix.com/documentation/2.0/manual/appendix/api/host/get
# Arguments:
#   $1 HOST NAME
# Returns:
#   ZABBIX HOST ID
#######################################
get_host_id() {
  PARAMS=$(cat << EOS
      {
          "jsonrpc": "2.0",
          "method": "host.get",
          "params": {
              "output": [
                  "hostid"
              ],
              "filter": {
                  "name": [
                      "$1"
                  ]
              }
          },
          "id": 1,
          "auth": "${TOKEN}"
      }
EOS
  )

  curl -s -H 'Content-Type:application/json-rpc' \
       ${URL} \
       -d "${PARAMS}" | /usr/local/bin/jq -r '.result[].hostid'
}

#######################################
# メンテナンス情報から maintenanceid を取得する
# https://www.zabbix.com/documentation/2.0/manual/appendix/api/maintenance/get
# Arguments:
#   $1 ZABBIX MAINTENANCE NAME
# Returns:
#   ZABBIX MAINTENANCE ID
#######################################
get_maintenance_id() {
  PARAMS=$(cat << EOS
      {
          "jsonrpc": "2.0",
          "method": "maintenance.get",
          "params": {
              "output": [
                  "maintenanceid"
              ],
              "filter": {
                  "name": [
                      "$1"
                  ]
              }
          },
          "id": 1,
          "auth": "${TOKEN}"
      }
EOS
  )

  curl -s -H 'Content-Type:application/json-rpc' \
       ${URL} \
       -d "${PARAMS}" | /usr/local/bin/jq -r '.result[].maintenanceid'
}

#######################################
# メンテナンスを作成する
# 「開始日時」と「終了日時」は「実行時から1日間」とする（デフォルト）
# 「メンテナンスタイプ」は「データ収集あり」とする（デフォルト）
# 「期間」は「実行時から1日間」で「一度限り」とする
# https://www.zabbix.com/documentation/2.0/manual/appendix/api/maintenance/create
# Arguments:
#   $1 ZABBIX MAINTENANCE NAME
#   $2 HOST NAME
#######################################
create_maintenance() {
  PARAMS=$(cat << EOS
      {
          "jsonrpc": "2.0",
          "method": "maintenance.create",
          "params": {
            "name": "$1",
            "hostids": [
                "$(get_host_id $2)"
            ],
            "timeperiods": [
                {
                    "period": 3600
                }
            ]
          },
          "id": 1,
          "auth": "${TOKEN}"
      }
EOS
  )

  curl -s -H 'Content-Type:application/json-rpc' \
       ${URL} \
       -d "${PARAMS}" | /usr/local/bin/jq .
}

#######################################
# メンテナンスを削除する
# https://www.zabbix.com/documentation/2.0/manual/appendix/api/maintenance/delete
# Arguments:
#   $1 ZABBIX MAINTENANCE NAME
#######################################
delete_maintenance() {
  PARAMS=$(cat << EOS
      {
          "jsonrpc": "2.0",
          "method": "maintenance.delete",
          "params": [
              $(get_maintenance_id $1)
          ],
          "id": 1,
          "auth": "${TOKEN}"
      }
EOS
  )

  curl -s -H 'Content-Type:application/json-rpc' \
       ${URL} \
       -d "${PARAMS}" | /usr/local/bin/jq .
}

#######################################
# メイン
# スクリプトのインポート時に実行する
#######################################
TOKEN=$(create_token)


