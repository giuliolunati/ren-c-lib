PACKAGE = r3
VERSION = 0.13.2
PLATFORM = kbox3
ARCH = arm
DESCRIPTION = "Rebol 3 base system"
DEB = ${PACKAGE}_${VERSION}_${PLATFORM}.deb
FILES = \
etc/plugins/webserver.desktop \
usr/bin/rebol.r \
usr/bin/r3 \
usr/bin/r3.bin \
usr/lib/r3/altjson.reb \
usr/lib/r3/android.reb \
usr/lib/r3/dot.reb \
usr/lib/r3/html.reb \
usr/lib/r3/httpd.reb \
usr/lib/r3/rem.reb \
usr/lib/r3/text.reb \
usr/lib/r3/webserver.reb \
usr/share/doc/r3/rem-tutorial.html \
usr/share/scripts/start-webserver.reb

${DEB}: data.tar.gz control.tar.gz debian-binary sl4abox.mak
	ar r $@ debian-binary control.tar.gz data.tar.gz

data.tar.gz: ${FILES} 
	tar cf data.tar ${FILES}
	rm -f data.tar.gz
	gzip data.tar

control.tar.gz: control preinst
	tar cf control.tar ./control ./preinst
	rm -f control.tar.gz
	gzip control.tar

debian-binary:
	echo 2.0 > $@

control: sl4abox.mak
	echo "Package: ${PACKAGE}" > $@
	echo "Version: ${VERSION}" >> $@
	echo "Architecture: ${ARCH}" >> $@
	echo "Description:" >> $@
	echo " ren-c libraries" >> $@
	echo "" >> $@

preinst: sl4abox.mak
	echo "mkdir -p /etc/plugins" > $@
	echo "mkdir -p /usr/bin" >> $@
	echo "mkdir -p /usr/lib/r3" >> $@
	echo "mkdir -p /usr/share/doc/r3" >> $@
	echo "mkdir -p /usr/share/scripts" >> $@
	chmod 755 $@

