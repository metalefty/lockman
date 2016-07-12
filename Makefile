test:
	bash ./test.sh

install: test
	install -m 0755 ./lockman.sh /usr/bin/lockman

uninstall:
	rm -i /usr/bin/lockman
