.PHONY:setup
setup:
	@echo "\e[32mSETUPを開始します\e[m"
	@echo "\e[32m - Gitのユーザ名を設定します\e[m"
	git config --global user.name "isucon"
	@echo "\e[32m - alpをインストールします\e[m"
	wget https://github.com/tkuchiki/alp/releases/download/v1.0.7/alp_linux_amd64.zip
	unzip alp_linux_amd64.zip -d alp_linux_amd64
	sudo install ./alp_linux_amd64/alp /usr/local/bin
	rm -r alp_linux_amd64 alp_linux_amd64.zip
	@echo "\e[32mSETUPが完了しました\e[m"

.PHONY:bench
bench:
	echo "" > /var/log/nginx/access.log
	@echo "\e[32mnginxのaccess.logを空にしました\e[m"
	cd /home/isucon/webapp && git pull origin main
	@echo "\e[32mGitHubのmainブランチから最新のソースを取得しました\e[m"
	@echo "\e[32mbenchを実行します\e[m"
	cd /home/isucon/bench && ./bench -all-addresses 127.0.0.11 -target 127.0.0.11:443 -tls -jia-service-url http://127.0.0.1:4999
	@echo "\e[32malpを実行します\e[m"
	cat /var/log/nginx/access.log | alp ltsv --sort sum -m "^/api/condition/[a-fA-F0-9\\-]+,^/api/isu/[a-fA-F0-9\\-]+/icon,^/api/isu/[a-fA-F0-9\\-]+/" --reverse -q
	@echo "\e[32m完了しました\e[m"


.PHONY: clear-accesslog
clear-accesslog:
	echo "" > /var/log/nginx/access.log
	@echo "\e[32mnginxのaccess.logを空にしました\e[m"

.PHONY:pull-github
pull-github:
	cd /home/isucon/webapp && git pull origin main
	@echo "\e[32mGitHubのmainブランチから最新のソースを取得しました\e[m"

.PHONY:do-bench
do-bench:
	@echo "\e[32mbenchを実行します\e[m"
	cd /home/isucon/bench && ./bench -all-addresses 127.0.0.11 -target 127.0.0.11:443 -tls -jia-service-url http://127.0.0.1:4999

.PHONY:alp-log
alp-log:
	@echo "\e[32malpを実行します\e[m"
	cat /var/log/nginx/access.log | alp ltsv --sort sum -m "^/\?jwt=[A-Za-z0-9\-_]+,^/api/condition/[a-fA-F0-9\\-]+,^/api/isu/[a-fA-F0-9\\-]+/icon,^/api/isu/[a-fA-F0-9\\-]+/,^/api/isu/[a-fA-F0-9\- ]+,^/isu/[a-fA-F0-9\\- ]+" --reverse -q
	@echo "\e[32m完了しました\e[m"