# SPDX-FileCopyrightText: © 2021 Dominick Grift <dominick.grift@defensec.nl>
# SPDX-License-Identifier: Unlicense

.PHONY: all clean policy check config_install modular_install

all: clean policy check

MCS = true
MODULES = $(shell find src -type f -name '*.cil' -printf '%p ')
POLVERS = 33
SELINUXTYPE = dssp5-fedora
VERBOSE = false

clean: clean.$(POLVERS)
clean.%:
	rm -f policy.$* file_contexts

policy: policy.$(POLVERS)
policy.%: $(MODULES)
ifeq ($(VERBOSE),false)
	secilc -OM $(MCS) --policyvers=$* $^
else
	secilc -vvv -OM $(MCS) --policyvers=$* $^
endif

check: check.$(POLVERS)
check.%:
	setfiles -c policy.$* file_contexts

config_install:
	install -d $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/files
	install -d $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users
	install -d $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/logins
	install -d -m0700 $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/policy
	echo -e """<!DOCTYPE busconfig PUBLIC\
 \"-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN\"\
\n	\"http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd\">\
\n<busconfig>\
\n<selinux>\
\n</selinux>\
\n</busconfig>""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/dbus_contexts
	echo -e """sys.serialtermdev\
\nuser.serialtermdev\
\ndracut.restore.run.file""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/customizable_types
	echo -e """gitshell.role:gitshell.subj\
\nsys.role:sys.user.subj\
\nuser.role:user.subj\
\nwheel.role:user.subj""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_type
	echo -e """user.serialtermdev\
\nsys.serialtermdev""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/securetty_types
	echo -e """/bin /usr/bin\
\n/etc/systemd/system /usr/lib/systemd/system\
\n/etc/systemd/system.attached /usr/lib/systemd/system\
\n/etc/systemd/system.control /usr/lib/systemd/system\
\n/etc/systemd/user /usr/lib/systemd/user\
\n/lib /usr/lib\
\n/lib64 /usr/lib\
\n/sbin /usr/bin\
\n/sysroot /\
\n/sysroot/bin /usr/bin\
\n/sysroot/etc/systemd/system /usr/lib/systemd/system\
\n/sysroot/etc/systemd/system.attached /usr/lib/systemd/system\
\n/sysroot/etc/systemd/system.control /usr/lib/systemd/system\
\n/sysroot/etc/systemd/user /usr/lib/systemd/user\
\n/sysroot/lib /usr/lib\
\n/sysroot/lib64 /usr/lib\
\n/sysroot/sbin /usr/bin\
\n/sysroot/usr/lib64 /usr/lib\
\n/sysroot/usr/libexec /usr/bin\
\n/sysroot/usr/local/bin /usr/bin\
\n/sysroot/usr/local/etc /etc\
\n/sysroot/usr/local/lib /usr/lib\
\n/sysroot/usr/local/lib64 /usr/lib\
\n/sysroot/usr/local/libexec /usr/bin\
\n/sysroot/usr/local/sbin /usr/bin\
\n/sysroot/usr/local/share /usr/share\
\n/sysroot/usr/local/src /usr/src\
\n/sysroot/usr/sbin /usr/bin\
\n/sysroot/usr/tmp /tmp\
\n/sysroot/var/mail /var/spool/mail\
\n/sysroot/var/lock /run/lock\
\n/sysroot/var/run /run\
\n/sysroot/var/tmp /tmp\
\n/usr/lib64 /usr/lib\
\n/usr/libexec /usr/bin\
\n/usr/local/bin /usr/bin\
\n/usr/local/etc /etc\
\n/usr/local/lib /usr/lib\
\n/usr/local/lib64 /usr/lib\
\n/usr/local/libexec /usr/bin\
\n/usr/local/sbin /usr/bin\
\n/usr/local/share /usr/share\
\n/usr/local/src /usr/src\
\n/usr/sbin /usr/bin\
\n/usr/tmp /tmp\
\n/var/cache/private /var/cache\
\n/var/lib/private /var/lib\
\n/var/lock /run/lock\
\n/var/log/private /var/log\
\n/var/mail /var/spool/mail\
\n/var/run /run\
\n/var/tmp /tmp""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/files/file_contexts.subs_dist
	echo "privsep_preauth=openssh.server.privsep.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/openssh_contexts
ifeq ($(MCS),false)
	echo -e """cdrom sys.id:sys.role:removable.stordev\
\ndisk sys.id:sys.role:removable.stordev\
\nfloppy sys.id:sys.role:removable.stordev""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/files/media
	echo -e """sys.role:sys.subj sys.role:sys.user.subj user.role:user.systemd.subj wheel.role:user.systemd.subj\
\nsys.role:login.subj sys.role:sys.user.subj user.role:user.subj wheel.role:user.subj\
\nsys.role:openssh.server.subj gitshell.role:gitshell.openssh.subj sys.role:sys.user.subj user.role:user.openssh.subj wheel.role:user.openssh.subj""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_contexts
	echo "sys.role:sys.user.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/failsafe_context
	echo "sys.id:sys.role:removable.fs" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/removable_context
	echo -e "sys.role:openssh.server.subj gitshell.role:gitshell.openssh.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/gitshell.id
	echo -e """sys.role:sys.subj sys.role:sys.user.subj\
\nsys.role:login.subj sys.role:sys.user.subj\
\nsys.role:openssh.server.subj sys.role:sys.user.subj""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/sys.id
	echo -e """sys.role:login.subj user.role:user.subj\
\nsys.role:sys.subj user.role:user.systemd.subj\
\nsys.role:openssh.server.subj user.role:user.openssh.subj""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/user.id
	echo -e """sys.role:login.subj wheel.role:user.subj\
\nsys.role:sys.subj wheel.role:user.systemd.subj\
\nsys.role:openssh.server.subj wheel.role:user.openssh.subj""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/wheel.id
else
	echo -e """cdrom sys.id:sys.role:removable.stordev:s0\
\ndisk sys.id:sys.role:removable.stordev:s0\
\nfloppy sys.id:sys.role:removable.stordev:s0""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/files/media
	echo -e """sys.role:sys.subj:s0 sys.role:sys.user.subj:s0 user.role:user.systemd.subj:s0 wheel.role:user.systemd.subj:s0\
\nsys.role:login.subj:s0 sys.role:sys.user.subj:s0 user.role:user.subj:s0 wheel.role:user.subj:s0\
\nsys.role:openssh.server.subj:s0 gitshell.role:gitshell.subj:s0 sys.role:sys.user.subj:s0 user.role:user.openssh.subj:s0 wheel.role:user.openssh.subj:s0""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_contexts
	echo "sys.role:sys.user.subj:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/failsafe_context
	echo "sys.id:sys.role:removable.fs:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/removable_context
	echo -e "sys.role:openssh.server.subj:s0 gitshell.role:gitshell.openssh.subj:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/gitshell.id
	echo -e """sys.role:sys.subj:s0 sys.role:sys.user.subj:s0\
\nsys.role:login.subj:s0 sys.role:sys.user.subj:s0\
\nsys.role:openssh.server.subj:s0 sys.role:sys.user.subj:s0""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/sys.id
	echo -e """sys.role:login.subj:s0 user.role:user.subj:s0\
\nsys.role:sys.subj:s0 user.role:user.systemd.subj:s0\
\nsys.role:openssh.server.subj:s0 user.role:user.openssh.subj:s0""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/user.id
	echo -e """sys.role:login.subj:s0 wheel.role:user.subj:s0\
\nsys.role:sys.subj:s0 wheel.role:user.systemd.subj:s0\
\nsys.role:openssh.server.subj:s0 wheel.role:user.openssh.subj:s0""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/wheel.id
endif

modular_install: config_install
	install -d -m0700 $(DESTDIR)/var/lib/selinux/$(SELINUXTYPE)
ifeq ($(MCS),false)
	sed -i 's/(mls true)/(mls false)/' src/misc/conf.cil
endif
ifndef DESTDIR
ifeq ($(VERBOSE),false)
	semodule --priority=100 -NP -s $(SELINUXTYPE) -i $(MODULES)
else
	semodule --priority=100 -NP -vvv -s $(SELINUXTYPE) -i $(MODULES)
endif
else
ifeq ($(VERBOSE),false)
	semodule --priority=100 -NP -s $(SELINUXTYPE) -i $(MODULES) -p $(DESTDIR)
else
	semodule --priority=100 -NP -vvv -s $(SELINUXTYPE) -i $(MODULES) -p $(DESTDIR)
endif
endif
ifeq ($(MCS),false)
	sed -i 's/(mls false)/(mls true)/' src/misc/conf.cil
endif
