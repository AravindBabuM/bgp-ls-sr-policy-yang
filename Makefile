LIBDIR := lib

.PHONY: check clean-model setup-yang-tools sync-draft validate-yang

all:: validate-yang

check:: validate-yang

setup-yang-tools: .yang-venv/.installed

.yang-venv/.installed: requirements.txt
	python3 -m venv .yang-venv
	.yang-venv/bin/python -m pip install -r requirements.txt
	touch $@

sync-draft:
	scripts/sync-draft-yang.py

validate-yang: setup-yang-tools
	PYANG=.yang-venv/bin/pyang XYM=.yang-venv/bin/xym \
		scripts/validate-yang.sh

clean-model:
	rm -f build/ietf-bgp-ls-sr-policy-tree.txt

-include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update --init
else
ifneq (,$(wildcard $(ID_TEMPLATE_HOME)))
	ln -s "$(ID_TEMPLATE_HOME)" $(LIBDIR)
else
	git clone -q --depth 10 -b main \
		https://github.com/martinthomson/i-d-template $(LIBDIR)
endif
endif
