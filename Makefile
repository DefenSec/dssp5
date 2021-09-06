# SPDX-FileCopyrightText: © 2021 Dominick Grift <dominick.grift@defensec.nl>
# SPDX-License-Identifier: Unlicense

.PHONY: all clean policy check config_install modular_install

all: clean policy check

MCS = true
MODULES = $(shell find src -type f -name '*.cil' -printf '%p ')
POLVERS = 32
SELINUXTYPE = dssp5-debian
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
	/bin/echo -e """<!DOCTYPE busconfig PUBLIC\
 \"-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN\"\
\n	\"http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd\">\
\n<busconfig>\
\n<selinux>\
\n</selinux>\
\n</busconfig>""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/dbus_contexts
	/bin/echo -e """sys.serialtermdev\
\nuser.serialtermdev""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/customizable_types
	/bin/echo -e """sys.role:sys.user.subj\
\nuser.role:user.subj\
\nwheel.role:user.subj""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_type
	/bin/echo -e """sys.serialtermdev\
\nuser.serialtermdev""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/securetty_types
	/bin/echo -e """/bin /usr/bin\
\n/etc/systemd/system /usr/lib/systemd/system\
\n/etc/systemd/system.attached /usr/lib/systemd/system\
\n/etc/systemd/system.control /usr/lib/systemd/system\
\n/etc/systemd/user /usr/lib/systemd/user\
\n/lib /usr/lib\
\n/lib32 /usr/lib\
\n/lib64 /usr/lib\
\n/libx32 /usr/lib\
\n/sbin /usr/bin\
\n/usr/lib/klibc/bin /usr/bin\
\n/usr/lib/x86_64-linux-gnu/e2fsprogs /usr/bin\
\n/usr/lib32 /usr/lib\
\n/usr/lib64 /usr/lib\
\n/usr/libexec /usr/bin\
\n/usr/libx32 /usr/lib\
\n/usr/local/bin /usr/bin\
\n/usr/local/etc /etc\
\n/usr/local/lib /usr/lib\
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
ifeq ($(MCS),false)
	/bin/echo -e """cdrom sys.id:sys.role:removable.stordev\
\ndisk sys.id:sys.role:removable.stordev\
\nfloppy sys.id:sys.role:removable.stordev""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/files/media
	echo "sys.role:sys.subj sys.role:sys.user.subj user.role:user.subj wheel.role:user.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_contexts
	echo "sys.role:sys.user.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/failsafe_context
	echo "sys.id:sys.role:removable.fs" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/removable_context
	echo "sys.role:sys.subj sys.role:sys.user.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/sys.id
	echo "sys.role:sys.subj user.role:user.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/user.id
	echo "sys.role:sys.subj wheel.role:user.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/wheel.id
else
	/bin/echo -e """cdrom sys.id:sys.role:removable.stordev:s0\
\ndisk sys.id:sys.role:removable.stordev:s0\
\nfloppy sys.id:sys.role:removable.stordev:s0""" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/files/media
	echo "sys.role:sys.subj:s0 sys.role:sys.user.subj:s0 user.role:user.subj:s0 wheel.role:user.subj:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_contexts
	echo "sys.role:sys.user.subj:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/failsafe_context
	echo "sys.id:sys.role:removable.fs:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/removable_context
	echo "sys.role:sys.subj:s0 sys.role:sys.user.subj:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/sys.id
	echo "sys.role:sys.subj:s0 user.role:user.subj:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/user.id
	echo "sys.role:sys.subj:s0 wheel.role:user.subj:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/users/wheel.id
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
