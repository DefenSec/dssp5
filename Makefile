# SPDX-FileCopyrightText: © 2021 Dominick Grift <dominick.grift@defensec.nl>
# SPDX-License-Identifier: Unlicense

.PHONY: all clean policy check config_install modular_install monolithic_install

all: clean policy check

MCS = true
MODULES = $(shell find src -type f -name '*.cil' -printf '%p ')
POLVERS = 33
SELINUXTYPE = dssp5-base-constrained
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
	echo "sys.role:sys.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_type
ifeq ($(MCS),false)
	echo "sys.role:sys.subj sys.role:sys.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_contexts
	echo "sys.role:sys.subj" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/failsafe_context
else
	echo "sys.role:sys.subj:s0 sys.role:sys.subj:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/default_contexts
	echo "sys.role:sys.subj:s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/failsafe_context
endif

modular_install: config_install
ifeq ($(MCS),false)
	sed -i 's/(mls true)/(mls false)/' src/misc/conf.cil
endif
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
ifeq ($(MCS),false)
	sed -i 's/(mls false)/(mls true)/' src/misc/conf.cil
endif

monolithic_install: config_install monolithic_install.$(POLVERS)
monolithic_install.%:
ifeq ($(MCS),false)
	echo "__default__:sys.id" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/seusers
else
	echo "__default__:sys.id:s0-s0" > $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/seusers
endif
	install -m 644 file_contexts $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/contexts/files/
	install -m 600 policy.$* $(DESTDIR)/etc/selinux/$(SELINUXTYPE)/policy/
