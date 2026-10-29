# BGP-LS SR Policy YANG model

This repository contains the work-in-progress `ietf-bgp-ls-sr-policy` YANG
module and its companion Internet-Draft:

* [`src/yang/ietf-bgp-ls-sr-policy.yang`](src/yang/ietf-bgp-ls-sr-policy.yang)
  augments the operational Link-State Database in
  [`draft-ietf-lsvr-bgp-ls-yang`](https://datatracker.ietf.org/doc/draft-ietf-lsvr-bgp-ls-yang/)
  with a representation of the SR Policy Candidate Path NLRI and its
  associated BGP-LS attributes, as defined in
  [RFC 9857](https://www.rfc-editor.org/rfc/rfc9857.html).
* [`draft-aravind-lsvr-bgp-ls-sr-policy-yang.md`](draft-aravind-lsvr-bgp-ls-sr-policy-yang.md)
  is the kramdown-rfc source for the Internet-Draft.

## Repository layout

~~~
.
|-- draft-aravind-lsvr-bgp-ls-sr-policy-yang.md
|-- src/yang/ietf-bgp-ls-sr-policy.yang
|-- scripts/fetch-yang-dependencies.sh
|-- scripts/sync-draft-yang.py
|-- scripts/validate-yang.sh
|-- .github/workflows/
|-- Dockerfile
`-- Makefile
~~~

## Validate the model

Python 3, Git, and `curl` are required.  The validation target creates a local
virtual environment, downloads the pinned upstream YANG dependencies into
`.cache/yang`, runs strict IETF `pyang` linting, generates a tree, and checks
that the module embedded in the draft is synchronized.

~~~ sh
make validate-yang
~~~

If `yanglint` is installed, the validation script runs it as a second parser.
The same checks run in GitHub Actions.  `make check` additionally runs the
Internet-Draft checks supplied by `i-d-template`.

After editing the standalone YANG module, update the copy in the draft with:

~~~ sh
make sync-draft
~~~

## Build the Internet-Draft

The first draft build downloads the
[`martinthomson/i-d-template`](https://github.com/martinthomson/i-d-template)
build support into `lib/`.

~~~ sh
make
~~~

Generated text and HTML drafts are intentionally ignored by Git.
