DATE:=$(shell date +%Y%m%d-%H%M%S)
CD:=$(CURDIR)
PROJECT_ROOT:=/home/isucon/webapp

# env.shに合わせて変更する
DB_HOST:=127.0.0.1
DB_PORT:=3306
DB_USER:=isucon
DB_PASS:=isucon
DB_NAME:=isucondition

MYSQL_CMD:=mysql -h$(DB_HOST) -P$(DB_PORT) -u$(DB_USER) -p$(DB_PASS) $(DB_NAME)

NGINX_LOG:=/var/log/nginx/access.log
MYSQL_LOG:=/var/log/mysql/slow-query.log

.PHONY: bench-%
bench-%: pull-%
	make build
	make etc
	make log-reset
	make restart slow-on
	@echo "\e[32mベンチの準備が完了しました\e[m"

.PHONY: bench
bench: build log-reset restart slow-on
	@echo "\e[32mベンチの準備が完了しました\e[m"

.PHONY: pull-%
pull-%:
	@echo "\e[32mgit pull\e[m"
	git fetch origin
	git checkout origin/$(patsubst pull-%,%,$@)
	git rebase main

.PHONY: build
build:
	@echo "\e[32mNode.js appをbuildします\e[m"
	cd nodejs && npm run build

.PHONY: etc
etc:
	@echo "\e[32m/etc にファイルを配置します\e[m"
	sudo rm -rf /etc/mysql
	sudo rm -rf /etc/nginx
	sudo cp -r mysql /etc/mysql
	sudo cp -r nginx /etc/nginx

.PHONY: etc-backup
etc-backup:
	@echo "\e[32m/etc を取得します\e[m"
	sudo mv /etc/mysql mysql
	sudo mv /etc/nginx nginx

.PHONY: cat
cat: cat-msg slow-log alp

.PHONY: cat-msg
cat-msg:
	git log -1 --pretty=format:"%s %h" | discocat

.PHONY: slow-log
slow-log:
	@echo "\e[32mslow-logsを出力します\e[m"
	sudo pt-query-digest --limit=100 --filter '$$event->{bytes} <= 100000' $(MYSQL_LOG) | discocat

.PHONY: mysqlslowdump
mysqlslowdump:
	sudo mysqldumpslow -s t $(SLOW_LOG) | head -n 20 | discocat

.PHONY: log-reset
log-reset:
	@echo "\e[32mlogファイルを初期化します\e[m"
	mkdir -p ~/logs/$(DATE)
	-sudo mv -f $(MYSQL_LOG) ~/logs/$(DATE)/slow-query.txt
	-sudo mv -f $(NGINX_LOG) ~/logs/$(DATE)/access.txt

ALPSORT=sum
ALPM=""
.PHONY: alp
alp:
	@echo "\e[32maccess logをalpで出力します\e[m"
	sudo cat $(NGINX_LOG) | alp ltsv --sort $(ALPSORT) -m $(ALPM) --reverse -q | discocat

.PHONY: restart
restart:
	@echo "\e[32mサービスを再起動します\e[m"
	sudo systemctl restart mysql.service
	sudo systemctl restart nginx.service
	sudo systemctl restart isucondition.nodejs.service

.PHONY: slow-on
slow-on:
	@echo "\e[32mMySQL slow-querry ONにします\e[m"
	sudo mysql -e "set global slow_query_log_file = '$(MYSQL_LOG)'; set global long_query_time = 0; set global slow_query_log = ON;"
	sudo mysql -e "show variables like 'slow%';"

.PHONY: slow-off
slow-off:
	@echo "\e[32mMySQL slow-querry OFFにします\e[m"
	sudo mysql -e "set global slow_query_log = OFF;"
	sudo mysql -e "show variables like 'slow%';"

.PHONY: setup
setup:
	@echo "\e[32mSETUPを開始します\e[m"
	@echo "\e[32m - Fishのリポジトリを追加します\e[m"
	sudo apt-add-repository ppa:fish-shell/release-3 -y
	sudo apt update
	@echo "\e[32m - 必要なパッケージをインストールします\e[m"
	sudo apt install -y percona-toolkit fish git unzip dstat
	@echo "\e[32m - fishを起動するように設定します\e[m"
	echo exec fish >> /home/isucon/.bashrc
	@echo "\e[32m - Gitのユーザ名を設定します\e[m"
	git config --global user.name "isucon"
	@echo "\e[32m - vimrcをちょっとだけ良くします\e[m"
	wget https://gist.githubusercontent.com/Hiroya-W/8d6f6dd6667f14b8182c2144c68fdcd3/raw/e71f3074d0cd452108eb3d0b2e9c60bc27c3c89c/.vimrc
	mv .vimrc ~/.vimrc
	@echo "\e[32m - alpをインストールします\e[m"
	wget https://github.com/tkuchiki/alp/releases/download/v1.0.7/alp_linux_amd64.zip
	unzip alp_linux_amd64.zip -d alp_linux_amd64
	sudo install ./alp_linux_amd64/alp /usr/local/bin
	rm -r alp_linux_amd64 alp_linux_amd64.zip
	@echo "\e[32m - discordcatをインストールします\e[m"
	go install github.com/wan-nyan-wan/discocat@latest
	mkdir -p ~/.config/discocat
	cp $HOME/go/pkg/mod/github.com/wan-nyan-wan/discocat@v0.0.0-20200904032027-e0871c377bd2 $HOME/.config/discocat/config.yml
	@echo "\e[32mSETUPが完了しました\e[m"