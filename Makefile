DATE:=$(shell date +%Y%m%d-%H%M%S)
CD:=$(CURDIR)
PROJECT_ROOT:=/home/isucon/webapp

# env.shに合わせて変更する
NGINX_LOG:=/var/log/nginx/access.log

.PHONY: bench
bench: isucon-user clear-accesslog pull-github do-bench alp
    @echo "\e[32mベンチの準備が完了しました\e[m"

.PHONY: isucon-user
isucon-user:
    sudo -i -u isucon
    @echo "\e[32mユーザーをisuconに設定しました\e[m"

.PHONY: clear-accesslog
clear-accesslog:
    echo "" > /var/log/nginx/access.log
    @echo "\e[32mnginxのaccess.logを空にしました\e[m"

.PHONY: pull-github
pull-github:
    cd /home/isucon/webapp && git pull origin main
    @echo "\e[32mGitHubのmainブランチから最新のソースを取得しました\e[m"

.PHONY: do-bench
do-bench:
    @echo "\e[32mbenchを実行します\e[m"
    cd /home/isucon/bench && ./bench -all-addresses 127.0.0.11 -target 127.0.0.11:443 -tls -jia-service-url http://127.0.0.1:4999

.PHONY: alp
alp:
    @echo "\e[32malpを実行します\e[m"
    cat /var/log/nginx/access.log | alp ltsv --sort sum -m "^/api/condition/[a-fA-F0-9\\-]+,^/api/isu/[a-fA-F0-9\\-]+/icon,^/api/isu/[a-fA-F0-9\\-]+/" --reverse -q
