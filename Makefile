# SPDX-FileCopyrightText: © 2021 Dominick Grift <dominick.grift@defensec.nl>
# SPDX-License-Identifier: Unlicense

.PHONY: all clean policy check config_install modular_install monolithic_install

all: clean policy check

MODULES = $(shell find src -type f -name '*.cil' -printf '%p ')
POLVERS = 33
SELINUXTYPE = dssp5-base
VERBOSE = false

clean: clean.$(POLVERS)
clean.%:
	rm -f policy.$* file_contexts

policy: policy.$(POLVERS)
policy.%: $(MODULES)
ifeq ($(VERBOSE),false)
	secilc -O --policyvers=$* $^
else
	secilc -vvv -O --policyvers=$* $^
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
	echo "sys.role:sys.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_type
	echo "sys.role:sys.subj sys.role:sys.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_contexts
	echo "sys.role:sys.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/failsafe_context

modular_install: config_install
	install -d -m0700 $(DESTDIR)/var/lib/selinux/$(SELINUXTYPE)
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

monolithic_install: config_install monolithic_install.$(POLVERS)
monolithic_install.%:
	echo "__default__:sys.id" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/seusers
	install -m 644 file_contexts $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/files/
	install -m 600 policy.$* $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/policy/
