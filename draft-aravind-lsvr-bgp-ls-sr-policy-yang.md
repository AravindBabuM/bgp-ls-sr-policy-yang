---
title: "A YANG Data Model for BGP-LS Segment Routing Policy"
abbrev: "BGP-LS SR Policy YANG"
category: std

docname: draft-aravind-lsvr-bgp-ls-sr-policy-yang-latest
submissiontype: IETF
number:
date:
consensus: true
v: 3
area: "Routing"
workgroup: "Link State Vector Routing"
keyword:
  - BGP-LS
  - Segment Routing
  - SR Policy
  - YANG
venue:
  group: "Link State Vector Routing"
  type: "Working Group"
  mail: "lsvr@ietf.org"
  arch: "https://mailarchive.ietf.org/arch/browse/lsvr/"
  github: "AravindBabuM/bgp-ls-sr-policy-yang"
  latest: "https://AravindBabuM.github.io/bgp-ls-sr-policy-yang/draft-aravind-lsvr-bgp-ls-sr-policy-yang.html"

author:
  -
    fullname: "Aravind Babu MahendraBabu"
    organization: "Cisco Systems, Inc."
    country: "India"
    email: "aramahen@cisco.com"
  -
    fullname: "Thanigaivel Manoharan"
    organization: "Cisco Systems, Inc."
    email: "thanmano@cisco.com"

normative:
  RFC7950:
  RFC8349:
  RFC9857:
  I-D.ietf-idr-bgp-model:
  I-D.ietf-lsvr-bgp-ls-yang:

informative:
  RFC3688:
  RFC6020:
  RFC6241:
  RFC6242:
  RFC8040:
  RFC8340:
  RFC8341:
  RFC8446:
  RFC9256:
  RFC9514:
  RFC9552:
  SERVICE-LAYER:
    title: "Cisco Service Layer Object Model: BGP-LS Topology"
    target: "https://github.com/Cisco-Service-Layer/service-layer-objmodel/blob/master/grpc/protos/sl_bgpls_topology.proto"
    date: "2026"
    author:
      -
        org: "Cisco Systems, Inc."

...

--- abstract

This document defines a YANG 1.1 data model for the operational state of
Segment Routing (SR) Policy candidate paths advertised using BGP Link-State
(BGP-LS).  The model augments the BGP-LS Link-State Database defined by
{{I-D.ietf-lsvr-bgp-ls-yang}} and represents the SR Policy Candidate Path
NLRI and the associated state TLVs specified by {{RFC9857}}.  Both SR-MPLS
and SRv6 candidate paths, Binding SIDs, constraints, segment lists, segment
descriptors, metrics, and unknown TLVs are covered.


--- middle

# Introduction

{{RFC9857}} defines the BGP-LS SR Policy Candidate Path NLRI and a set of
BGP-LS Attribute TLVs that report the operational state of an SR Policy at
candidate-path granularity.  This state includes the Binding SID, candidate
path status and names, path constraints, and one or more ordered segment
lists.  The information is useful to controllers and other consumers for
network visualization, path computation, reoptimization, and service
placement.

{{I-D.ietf-lsvr-bgp-ls-yang}} defines YANG 1.1 {{RFC7950}} configuration and
operational models for BGP-LS, BGP-LS-VPN, and BGP-LS-SPF under the routing
model of {{RFC8349}}.  Its operational Link-State Database models node, link,
prefix, and SRv6 SID NLRIs, and its common types already identify the SR Policy
Candidate Path NLRI and the Segment Routing Protocol-ID.  This document
augments that database with a typed operational representation of the SR
Policy NLRI and its attributes.

The model was informed by the `SLBgplsTopoSrPolicyData` and
`SLBgplsTopoSrPolicyAttr` messages in {{SERVICE-LAYER}}.  The protocol model
in {{RFC9857}} remains authoritative where the protobuf object model and the
published RFC differ.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

The terminology and abbreviations from {{RFC9256}}, {{RFC9552}}, and
{{RFC9857}} are used in this document.  In particular:

Candidate path (CP):
: A path that is associated with an SR Policy.  An SR Policy can have more
  than one candidate path, but only one is active at a time.

Headend:
: The node at which an SR Policy is instantiated and where traffic is
  steered onto the policy.

SID list:
: An ordered list of segments that describes a path through the SR domain.

# Model Scope and Design

The `ietf-bgp-ls-sr-policy` module is an operational-state augmentation.  It
does not configure SR Policies or change BGP-LS protocol behavior.  It adds
the `sr-pol-cp` container to the BGP-LS Link-State Database `instance`, as a
sibling of `nodes`, `links`, `prefixes`, `srv6-sids`, and `unknowns`.  The
container is present for an instance whose Protocol-ID is Segment Routing
(9).

This module augments only the BGP-LS `link-state` database.  It does not
augment the separate `link-state-spf` database because {{RFC9857}} does not
define the SR Policy Candidate Path NLRI for BGP-LS-SPF.

Each `candidate-path` entry is keyed by the decoded NLRI fields supplied by
two groupings:

* `sr-policy-node-descriptors` represents the Local Node Descriptors TLV.
  It contains the ASN, BGP Router-ID, Member-AS, and the IPv4 and IPv6
  Router-IDs used to identify the SR Policy headend.  Unspecified values are
  used for optional descriptors so that the operational list has a fixed
  YANG key; at least one headend IPv4 or IPv6 Router-ID is required.
* `sr-policy-candidate-path-descriptor` represents the mandatory SR Policy
  Candidate Path Descriptor TLV.  It contains Protocol-Origin, flags,
  endpoint, color, originator ASN, originator address, and discriminator.

The separate `attributes` container corresponds to
`SLBgplsTopoSrPolicyAttr` and models the BGP-LS Attribute:

* The SR-MPLS and SRv6 Binding SID containers preserve the allocation and
  fallback state defined by {{RFC9857}}.
* Candidate-path state, names, constraints, and optimization metrics are
  represented as typed leaves and containers.
* Segment lists and their segments are `ordered-by user`, because their wire
  order is significant.  An implementation-assigned index supplies a stable
  YANG list key when an optional Segment List Identifier is absent.
* Segment descriptor types A through K are represented as separate cases.
  SRv6 Endpoint Behavior and SID Structure information from {{RFC9514}}
  reuse the `bgp-ls-topo-srv6-sid-attr` grouping from the base Link-State
  Database model.
* Unknown attributes reuse the base model's
  `bgp-ls-topo-unknown-attr` grouping and are retained as type and
  uninterpreted value.

The flags that select IPv4 or IPv6 wire encodings are retained for diagnostic
fidelity even though the corresponding YANG leaves use `inet:ip-address`.
Bandwidth values are exposed as `decimal64` in bytes per second; the BGP-LS
wire format uses an IEEE 754 single-precision value.

# YANG Tree Diagram

This tree uses the notation from {{RFC8340}}.  The complete tree is generated
from the module during validation; the following diagram is abridged after
the segment descriptor choice.

~~~
module: ietf-bgp-ls-sr-policy

  augment /rt:routing/rt:control-plane-protocols
            /rt:control-plane-protocol/bgp:bgp/bgp:global
            /bgp:afi-safis/bgp:afi-safi/bgp-ls:link-state
            /bgp-ls:bgp-ls-topology/bgp-ls:instances/bgp-ls:instance:
    +--ro sr-pol-cp
       +--ro candidate-path*
               [as bgp-router-id member-as ipv4-router-id
                ipv6-router-id protocol-origin descriptor-flags
                endpoint color originator-as originator-address
                discriminator]
          +--ro as                           inet:as-number
          +--ro bgp-router-id                inet:ipv4-address
          +--ro member-as                    inet:as-number
          +--ro ipv4-router-id               inet:ipv4-address
          +--ro ipv6-router-id               inet:ipv6-address
          +--ro protocol-origin              protocol-origin
          +--ro descriptor-flags             descriptor-flags
          +--ro endpoint                     inet:ip-address
          +--ro color                        uint32
          +--ro originator-as                inet:as-number
          +--ro originator-address           inet:ip-address
          +--ro discriminator                uint32
          +--ro attributes
             +--ro policy-name?             string
             +--ro candidate-path-name?     string
             +--ro mpls-binding-sid!
             +--ro srv6-binding-sid* [binding-sid]
             |  +--ro srv6-sid-attributes
             |  +--ro unknown* [type]
             +--ro state!
             +--ro constraints!
             +--ro segment-list* [index]
             +--ro unknown* [type]
~~~

# YANG Module

The module imports the BGP module defined by {{I-D.ietf-idr-bgp-model}}
and the BGP-LS integration and Link-State Database modules defined by
{{I-D.ietf-lsvr-bgp-ls-yang}}.

<!-- YANG-MODEL:BEGIN -->
~~~ yang
module ietf-bgp-ls-sr-policy {
  yang-version 1.1;
  namespace
    "urn:ietf:params:xml:ns:yang:ietf-bgp-ls-sr-policy";
  prefix bgp-ls-sr-policy;

  import ietf-inet-types {
    prefix inet;
    reference
      "RFC 9911: Common YANG Data Types.";
  }
  import ietf-routing {
    prefix rt;
    reference
      "RFC 8349: A YANG Data Model for Routing Management
       (NMDA Version).";
  }
  import ietf-bgp {
    prefix bgp;
    reference
      "I-D.ietf-idr-bgp-model: BGP YANG Model for Service Provider
       Networks.";
  }
  import ietf-bgp-ls {
    prefix bgp-ls;
    reference
      "I-D.ietf-lsvr-bgp-ls-yang: A YANG Model for BGP-LS,
       BGP-LS-VPN, and BGP-LS-SPF.";
  }
  import ietf-bgp-lsdb {
    prefix bgp-lsdb;
    reference
      "I-D.ietf-lsvr-bgp-ls-yang: A YANG Model for BGP-LS,
       BGP-LS-VPN, and BGP-LS-SPF.";
  }
  organization
    "IETF LSVR Working Group";
  contact
    "WG Web:   <https://datatracker.ietf.org/wg/lsvr>
     WG List:  <mailto:lsvr@ietf.org>

     Authors:  Aravind Babu MahendraBabu
               <mailto:aramahen@cisco.com>
               Thanigaivel Manoharan
               <mailto:thanmano@cisco.com>";
  description
    "This module augments the operational Link-State Database in the
     BGP-LS YANG data model with a representation of the Segment
     Routing (SR) Policy Candidate Path NLRI and its associated
     BGP-LS attributes, as defined in RFC 9857.

     Copyright (c) 2026 IETF Trust and the persons identified as
     authors of the code.  All rights reserved.

     Redistribution and use in source and binary forms, with or
     without modification, is permitted pursuant to, and subject to
     the license terms contained in, the Revised BSD License set
     forth in Section 4.c of the IETF Trust's Legal Provisions
     Relating to IETF Documents
     (https://trustee.ietf.org/license-info).

     This version of this YANG module is part of RFC XXXX; see the
     RFC itself for full legal notices.";

  revision 2026-10-28 {
    description
      "Initial revision.";
    reference
      "RFC 9857: Advertisement of Segment Routing Policies Using
       BGP - Link State.
       I-D.aravind-lsvr-bgp-ls-sr-policy-yang: A YANG Data Model for
       BGP-LS Segment Routing Policy.";
  }

  typedef mpls-label {
    type uint32 {
      range "0..1048575";
    }
    description
      "A 20-bit MPLS label value.";
  }

  typedef protocol-origin {
    type uint8;
    description
      "The component responsible for instantiating an SR Policy
       candidate path.  Values are maintained in the IANA 'SR Policy
       Protocol-Origin' registry.  RFC 9857 initially defines PCEP
       (1), BGP SR Policy (2), configuration (3), PCEP via a PCE
       (10), BGP SR Policy via a PCE (20), and configuration via a
       PCE (30).";
    reference
      "RFC 9857, Sections 4 and 8.4.";
  }

  typedef metric-type {
    type uint8;
    description
      "An SR Policy metric type from the IANA 'BGP-LS SR Policy
       Metric Types' registry.";
    reference
      "RFC 9857, Sections 5.6.6, 5.7.2, and 8.6.";
  }

  typedef descriptor-flags {
    type bits {
      bit endpoint-ipv6 {
        position 0;
        description
          "The endpoint is encoded as an IPv6 address.";
      }
      bit originator-ipv6 {
        position 1;
        description
          "The originator is encoded as an IPv6 address.";
      }
    }
    description
      "Flags in the SR Policy Candidate Path Descriptor TLV.";
    reference
      "RFC 9857, Section 4.";
  }

  typedef binding-sid-flags {
    type bits {
      bit allocated {
        position 0;
        description
          "The Binding SID value is allocated.";
      }
      bit specified-unavailable {
        position 1;
        description
          "The specified Binding SID is unavailable.";
      }
      bit srlb {
        position 2;
        description
          "The Binding SID is from the headend SRLB.";
      }
      bit fallback {
        position 3;
        description
          "The value was dynamically allocated due to fallback.";
      }
    }
    description
      "Flags in the SR Binding SID TLV.  The SRLB flag applies only
       to an SR-MPLS Binding SID.";
    reference
      "RFC 9857, Section 5.1.";
  }

  typedef srv6-binding-sid-flags {
    type bits {
      bit allocated {
        position 0;
        description
          "The SRv6 Binding SID value is allocated.";
      }
      bit specified-unavailable {
        position 1;
        description
          "The specified SRv6 Binding SID is unavailable.";
      }
      bit fallback {
        position 2;
        description
          "The value was dynamically allocated due to fallback.";
      }
    }
    description
      "Flags in the SRv6 Binding SID TLV.";
    reference
      "RFC 9857, Section 5.2.";
  }

  typedef candidate-path-state-flags {
    type bits {
      bit administrative-shutdown {
        position 0;
        description
          "The candidate path is administratively shut down.";
      }
      bit active {
        position 1;
        description
          "The candidate path is active in the forwarding plane.";
      }
      bit backup {
        position 2;
        description
          "The candidate path is a backup path.";
      }
      bit evaluated {
        position 3;
        description
          "The candidate path has been evaluated for validity.";
      }
      bit valid {
        position 4;
        description
          "The candidate path has at least one valid SID list.";
      }
      bit on-demand-nexthop {
        position 5;
        description
          "The path was instantiated by an on-demand nexthop
           trigger.";
      }
      bit delegated {
        position 6;
        description
          "The path was delegated to a PCE or controller.";
      }
      bit provisioned {
        position 7;
        description
          "The path was provisioned by a PCE or controller.";
      }
      bit drop-upon-invalid {
        position 8;
        description
          "Drop-upon-invalid behavior is requested.";
      }
      bit transit-eligible {
        position 9;
        description
          "The path is eligible for use as a transit policy.";
      }
      bit dropping {
        position 10;
        description
          "The active path is dropping traffic due to
           drop-upon-invalid behavior.";
      }
    }
    description
      "Operational state flags for an SR Policy candidate path.";
    reference
      "RFC 9857, Section 5.3.";
  }

  typedef candidate-path-constraint-flags {
    type bits {
      bit srv6-dataplane {
        position 0;
        description
          "Use the SRv6 dataplane instead of SR-MPLS.";
      }
      bit protected {
        position 1;
        description
          "Prefer protected SIDs.";
      }
      bit unprotected {
        position 2;
        description
          "Prefer unprotected SIDs.";
      }
      bit specified-algorithm {
        position 3;
        description
          "Use SIDs belonging to the specified SR Algorithm.";
      }
      bit specified-topology {
        position 4;
        description
          "Use SIDs belonging to the specified topology.";
      }
      bit strict {
        position 5;
        description
          "Treat the protection preference as a strict constraint.";
      }
      bit fixed {
        position 6;
        description
          "The path is fixed after computation.";
      }
      bit hop-by-hop {
        position 7;
        description
          "Use only adjacency SIDs in hop-by-hop fashion.";
      }
    }
    description
      "Flags in the SR Candidate Path Constraints TLV.";
    reference
      "RFC 9857, Section 5.6.";
  }

  typedef disjoint-request-flags {
    type bits {
      bit srlg {
        position 0;
        description
          "SRLG disjointness is requested.";
      }
      bit node {
        position 1;
        description
          "Node disjointness is requested.";
      }
      bit link {
        position 2;
        description
          "Link disjointness is requested.";
      }
      bit fallback {
        position 3;
        description
          "Fallback to lower disjointness is permitted.";
      }
      bit best-path-fallback {
        position 4;
        description
          "Fallback to the default best path is permitted.";
      }
    }
    description
      "Requested SR disjointness constraints.";
    reference
      "RFC 9857, Section 5.6.4.";
  }

  typedef disjoint-status-flags {
    type bits {
      bit srlg {
        position 0;
        description
          "SRLG disjointness was achieved.";
      }
      bit node {
        position 1;
        description
          "Node disjointness was achieved.";
      }
      bit link {
        position 2;
        description
          "Link disjointness was achieved.";
      }
      bit fallback {
        position 3;
        description
          "Computation fell back to lower disjointness.";
      }
      bit best-path-fallback {
        position 4;
        description
          "Computation fell back to the default best path.";
      }
      bit invalid {
        position 5;
        description
          "The constraint could not be met and the path is invalid.";
      }
    }
    description
      "Achieved SR disjointness status.";
    reference
      "RFC 9857, Section 5.6.4.";
  }

  typedef bidirectional-flags {
    type bits {
      bit reverse {
        position 0;
        description
          "This candidate path is the reverse path.";
      }
      bit co-routed {
        position 1;
        description
          "The bidirectional path is co-routed.";
      }
    }
    description
      "Flags for an SR bidirectional group constraint.";
    reference
      "RFC 9857, Section 5.6.5.";
  }

  typedef metric-constraint-flags {
    type bits {
      bit optimization-metric {
        position 0;
        description
          "This is the optimization metric for the dynamic path.";
      }
      bit margin-present {
        position 1;
        description
          "A metric margin is present.";
      }
      bit absolute-margin {
        position 2;
        description
          "The margin is absolute rather than a percentage.";
      }
      bit bound-present {
        position 3;
        description
          "A metric bound is present.";
      }
    }
    description
      "Flags for an SR Metric Constraint sub-TLV.";
    reference
      "RFC 9857, Section 5.6.6.";
  }

  typedef segment-list-flags {
    type bits {
      bit srv6-dataplane {
        position 0;
        description
          "The SID list contains SRv6 SIDs.";
      }
      bit explicit {
        position 1;
        description
          "The SID list belongs to an explicit candidate path.";
      }
      bit computed {
        position 2;
        description
          "The SID list was computed.";
      }
      bit verified {
        position 3;
        description
          "The SID list passed verification or needed none.";
      }
      bit resolved {
        position 4;
        description
          "The first segment was resolved.";
      }
      bit computation-failed {
        position 5;
        description
          "Dynamic path computation failed.";
      }
      bit specified-algorithm {
        position 6;
        description
          "All SIDs belong to the specified algorithm.";
      }
      bit specified-topology {
        position 7;
        description
          "All SIDs belong to the specified topology.";
      }
      bit fault-monitor-removed {
        position 8;
        description
          "Fault monitoring removed the SID list from forwarding.";
      }
    }
    description
      "Flags in the SR Segment List TLV.";
    reference
      "RFC 9857, Section 5.7.";
  }

  typedef segment-flags {
    type bits {
      bit sid-present {
        position 0;
        description
          "The SID field is present.";
      }
      bit explicitly-provisioned {
        position 1;
        description
          "The SID was explicitly provisioned.";
      }
      bit verified {
        position 2;
        description
          "The SID passed verification or needed none.";
      }
      bit resolved {
        position 3;
        description
          "The SID was resolved or needed no resolution.";
      }
      bit algorithm-valid {
        position 4;
        description
          "The algorithm in the descriptor is valid.";
      }
    }
    description
      "Flags in an SR Segment sub-TLV.";
    reference
      "RFC 9857, Section 5.7.1.";
  }

  typedef segment-list-metric-flags {
    type bits {
      bit margin-present {
        position 0;
        description
          "A metric margin is present.";
      }
      bit absolute-margin {
        position 1;
        description
          "The margin is absolute rather than a percentage.";
      }
      bit bound-present {
        position 2;
        description
          "A metric bound is present.";
      }
      bit value-present {
        position 3;
        description
          "A computed metric value is present.";
      }
    }
    description
      "Flags in an SR Segment List Metric sub-TLV.";
    reference
      "RFC 9857, Section 5.7.2.";
  }

  grouping sr-policy-node-descriptors {
    description
      "Decoded fields of the Local Node Descriptors TLV identifying
       the SR Policy headend.";
    reference
      "RFC 9857, Section 3.";

    leaf as {
      type inet:as-number;
      description
        "Autonomous System Number in Node Descriptor TLV 512.  A
         value of zero indicates that the descriptor was absent.";
    }
    leaf bgp-router-id {
      type inet:ipv4-address;
      description
        "BGP Router-ID in Node Descriptor TLV 516.  The unspecified
         address indicates that the descriptor was absent.";
    }
    leaf member-as {
      type inet:as-number;
      description
        "BGP Confederation Member ASN in Node Descriptor TLV 517.  A
         value of zero indicates that the descriptor was absent.";
    }

    leaf ipv4-router-id {
      type inet:ipv4-address;
      description
        "IPv4 Router-ID of the headend from TLV 1028.  The
         unspecified address is used when only an IPv6 Router-ID is
         present.";
    }
    leaf ipv6-router-id {
      type inet:ipv6-address;
      description
        "IPv6 Router-ID of the headend from TLV 1029.  The
         unspecified address is used when only an IPv4 Router-ID is
         present.";
    }
  }

  grouping sr-policy-candidate-path-descriptor {
    description
      "Decoded fields of the mandatory SR Policy Candidate Path
       Descriptor TLV.";
    reference
      "RFC 9857, Section 4.";

    leaf protocol-origin {
      type protocol-origin;
      mandatory true;
      description
        "Protocol or component that instantiated the path.";
    }
    leaf descriptor-flags {
      type descriptor-flags;
      mandatory true;
      description
        "Address-family flags from the descriptor TLV.";
    }
    leaf endpoint {
      type inet:ip-address;
      mandatory true;
      description
        "SR Policy endpoint.";
    }
    leaf color {
      type uint32;
      mandatory true;
      description
        "SR Policy color.";
    }
    leaf originator-as {
      type inet:as-number;
      mandatory true;
      description
        "ASN of the candidate-path originator.";
    }
    leaf originator-address {
      type inet:ip-address;
      mandatory true;
      description
        "Address of the candidate-path originator.";
    }
    leaf discriminator {
      type uint32;
      mandatory true;
      description
        "Candidate-path discriminator.";
    }
  }

  grouping candidate-path-constraints {
    description
      "Constraints associated with an SR Policy candidate path.";

    container constraints {
      presence "An SR Candidate Path Constraints TLV was received.";
      description
        "Constraints and optimization objectives for the path.";
      reference
        "RFC 9857, Section 5.6.";

      leaf flags {
        type candidate-path-constraint-flags;
        description
          "Constraint flags.";
      }
      leaf multi-topology-id {
        type uint16 {
          range "0..4095";
        }
        description
          "Preferred IGP multi-topology identifier.";
      }
      leaf algorithm {
        type uint8;
        description
          "Preferred SR Algorithm.";
      }

      container affinity {
        presence "An SR Affinity Constraint sub-TLV was received.";
        description
          "Extended Administrative Group affinity constraints.
           Each leaf-list entry represents one 32-bit word, in wire
           order.";
        reference
          "RFC 9857, Section 5.6.1.";

        leaf-list exclude-any {
          type uint32;
          ordered-by user;
          description
            "Affinity words for the exclude-any constraint.";
        }
        leaf-list include-any {
          type uint32;
          ordered-by user;
          description
            "Affinity words for the include-any constraint.";
        }
        leaf-list include-all {
          type uint32;
          ordered-by user;
          description
            "Affinity words for the include-all constraint.";
        }
      }

      leaf-list excluded-srlg {
        type uint32;
        ordered-by user;
        description
          "Shared Risk Link Group values excluded from the path.";
        reference
          "RFC 9857, Section 5.6.2.";
      }
      leaf bandwidth {
        type decimal64 {
          fraction-digits 2;
        }
        units "bytes per second";
        description
          "Requested bandwidth.  The protocol encodes this value as
           an IEEE 754 single-precision floating-point number.";
        reference
          "RFC 9857, Section 5.6.3.";
      }

      container disjoint-group {
        presence
          "An SR Disjoint Group Constraint sub-TLV was received.";
        description
          "Requested and achieved path disjointness.";
        reference
          "RFC 9857, Section 5.6.4.";

        leaf request-flags {
          type disjoint-request-flags;
          description
            "Requested disjointness properties.";
        }
        leaf status-flags {
          type disjoint-status-flags;
          description
            "Achieved disjointness properties.";
        }
        leaf group-id {
          type uint32;
          mandatory true;
          description
            "Disjoint group identifier.";
        }
      }

      container bidirectional-group {
        presence
          "An SR Bidirectional Group Constraint sub-TLV was
           received.";
        description
          "Bidirectional path association.";
        reference
          "RFC 9857, Section 5.6.5.";

        leaf flags {
          type bidirectional-flags;
          description
            "Bidirectional group flags.";
        }
        leaf group-id {
          type uint32;
          mandatory true;
          description
            "Bidirectional group identifier.";
        }
      }

      list metric {
        key "type";
        description
          "Metric constraints associated with the candidate path.";
        reference
          "RFC 9857, Section 5.6.6.";

        leaf type {
          type metric-type;
          description
            "Metric type code point.";
        }
        leaf flags {
          type metric-constraint-flags;
          description
            "Metric constraint flags.";
        }
        leaf margin {
          type uint32;
          description
            "Absolute or percentage metric margin.";
        }
        leaf bound {
          type uint32;
          description
            "Worst metric value allowed for a valid path.";
        }
      }
    }
  }

  grouping segment-descriptor {
    description
      "Descriptor for one of the segment types defined by RFC 9857.";

    choice descriptor {
      description
        "Descriptor fields selected according to the segment type.";

      case type-a {
        container type-a {
          when "../type = 1";
          description
            "Type A: SR-MPLS label descriptor.";
          leaf algorithm {
            type uint8;
            mandatory true;
            description
              "IGP Algorithm used to select the SID.";
          }
        }
      }
      case type-b {
        container type-b {
          when "../type = 2";
          description
            "Type B: SRv6 SID descriptor.";
          leaf algorithm {
            type uint8;
            mandatory true;
            description
              "IGP Algorithm used to select the SID.";
          }
        }
      }
      case type-c {
        container type-c {
          when "../type = 3";
          description
            "Type C: IPv4 node address for an SR-MPLS Prefix SID.";
          leaf algorithm {
            type uint8;
            mandatory true;
            description
              "IGP Algorithm used to select the SID.";
          }
          leaf node-address {
            type inet:ipv4-address;
            mandatory true;
            description
              "IPv4 address associated with the node.";
          }
        }
      }
      case type-d {
        container type-d {
          when "../type = 4";
          description
            "Type D: IPv6 node address for an SR-MPLS Prefix SID.";
          leaf algorithm {
            type uint8;
            mandatory true;
            description
              "IGP Algorithm used to select the SID.";
          }
          leaf node-address {
            type inet:ipv6-address;
            mandatory true;
            description
              "IPv6 global address associated with the node.";
          }
        }
      }
      case type-e {
        container type-e {
          when "../type = 5";
          description
            "Type E: IPv4 node and local interface identifier.";
          leaf node-address {
            type inet:ipv4-address;
            mandatory true;
            description
              "IPv4 address associated with the node.";
          }
          leaf local-interface-id {
            type uint32;
            mandatory true;
            description
              "Local interface identifier.";
          }
        }
      }
      case type-f {
        container type-f {
          when "../type = 6";
          description
            "Type F: IPv4 local and remote interface addresses.";
          leaf local-interface-address {
            type inet:ipv4-address;
            mandatory true;
            description
              "Local interface address.";
          }
          leaf remote-interface-address {
            type inet:ipv4-address;
            mandatory true;
            description
              "Remote interface address; zero may indicate that the
               value is unused.";
          }
        }
      }
      case type-g {
        container type-g {
          when "../type = 7";
          description
            "Type G: IPv6 node addresses and interface identifiers
             for an SR-MPLS adjacency.";
          uses ipv6-node-and-interface-pair;
        }
      }
      case type-h {
        container type-h {
          when "../type = 8";
          description
            "Type H: IPv6 local and remote interface addresses for
             an SR-MPLS adjacency.";
          uses ipv6-interface-address-pair;
        }
      }
      case type-i {
        container type-i {
          when "../type = 9";
          description
            "Type I: IPv6 node address for an SRv6 End SID.";
          leaf algorithm {
            type uint8;
            mandatory true;
            description
              "IGP Algorithm used to select the SID.";
          }
          leaf node-address {
            type inet:ipv6-address;
            mandatory true;
            description
              "IPv6 global address associated with the node.";
          }
        }
      }
      case type-j {
        container type-j {
          when "../type = 10";
          description
            "Type J: IPv6 node addresses and interface identifiers
             for an SRv6 End.X SID.";
          uses ipv6-node-and-interface-pair;
        }
      }
      case type-k {
        container type-k {
          when "../type = 11";
          description
            "Type K: IPv6 local and remote interface addresses for
             an SRv6 End.X SID.";
          uses ipv6-interface-address-pair;
        }
      }
    }
  }

  grouping ipv6-node-and-interface-pair {
    description
      "IPv6 node addresses and interface identifiers for both ends
       of a link.";

    leaf local-node-address {
      type inet:ipv6-address;
      mandatory true;
      description
        "IPv6 global address of the local node.";
    }
    leaf local-interface-id {
      type uint32;
      mandatory true;
      description
        "Local node interface identifier.";
    }
    leaf remote-node-address {
      type inet:ipv6-address;
      mandatory true;
      description
        "IPv6 global address of the remote node; zero may indicate
         that the value is unused.";
    }
    leaf remote-interface-id {
      type uint32;
      mandatory true;
      description
        "Remote node interface identifier; zero may indicate that the
         value is unused.";
    }
  }

  grouping ipv6-interface-address-pair {
    description
      "IPv6 interface addresses for both ends of a link.";

    leaf local-interface-address {
      type inet:ipv6-address;
      mandatory true;
      description
        "IPv6 global address of the local interface.";
    }
    leaf remote-interface-address {
      type inet:ipv6-address;
      mandatory true;
      description
        "IPv6 global address of the remote interface.";
    }
  }

  grouping segment-lists {
    description
      "SID lists belonging to an SR Policy candidate path.";

    list segment-list {
      key "index";
      ordered-by user;
      description
        "A SID list in the order received.  The index provides a
         stable key even when the optional protocol identifier is
         absent or duplicated by a malformed advertisement.";
      reference
        "RFC 9857, Section 5.7.";

      leaf index {
        type uint32;
        description
          "Implementation-assigned ordinal for this SID list.";
      }
      leaf flags {
        type segment-list-flags;
        description
          "SID-list state and dataplane flags.";
      }
      leaf multi-topology-id {
        type uint16 {
          range "0..4095";
        }
        description
          "Multi-topology identifier used by the SID list.";
      }
      leaf algorithm {
        type uint8;
        description
          "SR Algorithm used by the SID list.";
      }
      leaf weight {
        type uint32;
        description
          "Weight used for load balancing across SID lists.";
      }
      leaf identifier {
        type uint32;
        description
          "Candidate-path-scoped SID-list identifier.  Zero means
           that no identifier is associated with the SID list.";
        reference
          "RFC 9857, Section 5.7.4.";
      }

      list segment {
        key "index";
        ordered-by user;
        description
          "An ordered segment in the SID list.";
        reference
          "RFC 9857, Section 5.7.1.";

        leaf index {
          type uint32;
          description
            "Zero-based position of the segment in the SID list.";
        }
        leaf type {
          type uint8 {
            range "1..255";
          }
          mandatory true;
          description
            "Segment Descriptor Type from the IANA 'BGP-LS SR
             Segment Descriptor Types' registry.";
        }
        leaf flags {
          type segment-flags;
          description
            "Segment state flags.";
        }
        choice sid {
          description
            "Resolved or explicitly provisioned SID value.";
          case mpls {
            leaf mpls-label {
              type mpls-label;
              description
                "SR-MPLS label.";
            }
          }
          case srv6 {
            leaf srv6-sid {
              type inet:ipv6-address;
              description
                "SRv6 SID.";
            }
          }
        }

        uses segment-descriptor;
        uses bgp-lsdb:bgp-ls-topo-srv6-sid-attr;
        uses bgp-lsdb:bgp-ls-topo-unknown-attr;
      }

      list metric {
        key "type";
        description
          "Computed metric values for this SID list.";
        reference
          "RFC 9857, Section 5.7.2.";

        leaf type {
          type metric-type;
          description
            "Metric type code point.";
        }
        leaf flags {
          type segment-list-metric-flags;
          description
            "Metric presence and interpretation flags.";
        }
        leaf margin {
          type uint32;
          description
            "Absolute or percentage metric margin.";
        }
        leaf bound {
          type uint32;
          description
            "Worst metric value allowed for a valid path.";
        }
        leaf value {
          type uint32;
          description
            "Computed metric value.";
        }
      }

      leaf bandwidth {
        type decimal64 {
          fraction-digits 2;
        }
        units "bytes per second";
        description
          "Allocated bandwidth.  The protocol encodes this value as
           an IEEE 754 single-precision floating-point number.";
        reference
          "RFC 9857, Section 5.7.3.";
      }
      uses bgp-lsdb:bgp-ls-topo-unknown-attr;
    }
  }

  grouping sr-policy-candidate-paths {
    description
      "Operational SR Policy candidate paths advertised in BGP-LS.";

    container sr-pol-cp {
      description
        "BGP-LS topology entries for SR Policy Candidate Path
         NLRIs.";

      list candidate-path {
        must "ipv4-router-id != '0.0.0.0' or "
           + "ipv6-router-id != '::'" {
          error-message
            "At least one headend IPv4 or IPv6 Router-ID must be "
          + "present.";
          description
            "RFC 9857 requires at least one auxiliary Router-ID for
             the SR Policy headend.";
        }
        key "as bgp-router-id member-as ipv4-router-id "
          + "ipv6-router-id protocol-origin descriptor-flags "
          + "endpoint color originator-as originator-address "
          + "discriminator";
        description
          "An SR Policy candidate-path NLRI and its BGP-LS
           attributes.  The list key is the decoded Local Node
           Descriptors TLV followed by the mandatory SR Policy
           Candidate Path Descriptor TLV.";
        reference
          "RFC 9857, Sections 3 through 5.";

        uses sr-policy-node-descriptors;
        uses sr-policy-candidate-path-descriptor;

        container attributes {
          description
            "Decoded BGP-LS Attribute TLVs associated with the SR
             Policy Candidate Path NLRI.";

          leaf policy-name {
            type string {
              length "0..255";
            }
            description
              "Symbolic SR Policy name from TLV 1213.";
            reference
              "RFC 9857, Section 5.4.";
          }
          leaf candidate-path-name {
            type string {
              length "0..255";
            }
            description
              "Symbolic candidate-path name from TLV 1203.";
            reference
              "RFC 9857, Section 5.5.";
          }

          container mpls-binding-sid {
            presence "An SR Binding SID TLV was received.";
            description
              "SR-MPLS Binding SID state.  The deprecated SRv6
               encoding of TLV 1201 is intentionally not represented
               here; SRv6 Binding SIDs are represented by TLV 1212
               below.";
            reference
              "RFC 9857, Section 5.1.";

            leaf flags {
              type binding-sid-flags;
              description
                "Binding SID status flags.";
            }
            leaf binding-sid {
              type mpls-label;
              description
                "Allocated or operational Binding SID.";
            }
            leaf specified-binding-sid {
              type mpls-label;
              description
                "Explicitly specified Binding SID.";
            }
          }

          list srv6-binding-sid {
            key "binding-sid";
            description
              "An SRv6 Binding SID associated with the candidate
               path.";
            reference
              "RFC 9857, Section 5.2.";

            leaf binding-sid {
              type inet:ipv6-address;
              description
                "Allocated or operational SRv6 Binding SID.";
            }
            leaf flags {
              type srv6-binding-sid-flags;
              description
                "SRv6 Binding SID status flags.";
            }
            leaf specified-binding-sid {
              type inet:ipv6-address;
              description
                "Explicitly specified SRv6 Binding SID.";
            }
            uses bgp-lsdb:bgp-ls-topo-srv6-sid-attr;
            uses bgp-lsdb:bgp-ls-topo-unknown-attr;
          }

          container state {
            presence "An SR Candidate Path State TLV was received.";
            description
              "Operational status at candidate-path level.";
            reference
              "RFC 9857, Section 5.3.";

            leaf priority {
              type uint8;
              mandatory true;
              description
                "Candidate-path priority.";
            }
            leaf flags {
              type candidate-path-state-flags;
              description
                "Candidate-path operational state flags.";
            }
            leaf preference {
              type uint32;
              mandatory true;
              description
                "Candidate-path preference.";
            }
          }

          uses candidate-path-constraints;
          uses segment-lists;
          uses bgp-lsdb:bgp-ls-topo-unknown-attr;
        }
      }
    }
  }

  augment "/rt:routing/rt:control-plane-protocols/"
        + "rt:control-plane-protocol/bgp:bgp/bgp:global/"
        + "bgp:afi-safis/bgp:afi-safi/bgp-ls:link-state/"
        + "bgp-ls:bgp-ls-topology/bgp-ls:instances/"
        + "bgp-ls:instance" {
    when "bgp-ls:protocol = 'sr'" {
      description
        "SR Policy candidate-path NLRIs use the Segment Routing
         Protocol-ID (9).";
    }
    description
      "Add SR Policy Candidate Path NLRI entries to the BGP-LS
       Link-State Database.  This augmentation targets BGP-LS and not
       the separate BGP-LS-SPF Link-State Database instantiation.";
    uses sr-policy-candidate-paths;
  }
}
~~~
<!-- YANG-MODEL:END -->

# Manageability Considerations

The augmentation is read-only and therefore introduces no new configuration,
RPC, action, or notification.  Existing BGP and BGP-LS operational procedures
continue to apply.  An implementation SHOULD retain unknown TLVs to preserve
visibility when producers and consumers support different extension sets.

The number of candidate paths, SID lists, segments, metrics, and unknown TLVs
is controlled by received BGP-LS information.  Implementations SHOULD apply
the same resource limits and malformed-TLV handling used for the underlying
BGP-LS database.

# Security Considerations

The YANG module specified in this document defines schema for data that is
accessed through network management protocols such as NETCONF {{RFC6241}} or
RESTCONF {{RFC8040}}.  The lowest NETCONF layer is the secure transport layer,
and the mandatory-to-implement secure transport is Secure Shell (SSH)
{{RFC6242}}.  The lowest RESTCONF layer is HTTPS, and TLS {{RFC8446}} is
mandatory to implement.

The Network Configuration Access Control Model (NACM) {{RFC8341}} provides the
means to restrict access for particular users to a preconfigured subset of
all available protocol operations and content.

All nodes introduced by this module are read-only.  They can nevertheless
expose commercially or operationally sensitive information, including
headend and endpoint addresses, Binding SIDs, complete SID lists, path
constraints, bandwidth, and disjointness relationships.  Unauthorized read
access could reveal network topology, traffic-engineering intent, and
protection strategy.  Implementations MUST apply appropriate access control
to the `sr-pol-cp` subtree and SHOULD expose it only to trusted principals.

The security considerations of {{RFC9256}}, {{RFC9552}}, {{RFC9857}},
{{I-D.ietf-idr-bgp-model}}, and {{I-D.ietf-lsvr-bgp-ls-yang}} also apply.

# IANA Considerations

This document requests IANA to register the following URI in the "IETF XML
Registry" {{RFC3688}}:

~~~
URI: urn:ietf:params:xml:ns:yang:ietf-bgp-ls-sr-policy
Registrant Contact: The IESG.
XML: N/A; the requested URI is an XML namespace.
~~~

This document also requests IANA to register the following YANG module in the
"YANG Module Names" registry {{RFC6020}}:

~~~
name: ietf-bgp-ls-sr-policy
namespace: urn:ietf:params:xml:ns:yang:ietf-bgp-ls-sr-policy
prefix: bgp-ls-sr-policy
reference: RFC XXXX
~~~


--- back

# Acknowledgments
{:numbered="false"}

The authors thank the authors and contributors of {{RFC9857}}, the authors of
{{I-D.ietf-lsvr-bgp-ls-yang}}, and the contributors to the Cisco Service Layer
BGP-LS topology object model.
