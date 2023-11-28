---
title: Budgetable
title-suffix: Portfolio
date: 2022-06-21 -- 2022-10-27
keywords: [Finance, Auth0, Stripe, WebAssembly, Haskell, Rust]
website: https://budgetable.net
abstract-title: Summary
abstract:
  Budgetable is a budget management and personal finance forecasting tool. It doesn't store any
  financial information on any server, and performs all calculations in the browser. The front-end
  is written in Rust, and the microservices are written in Haskell. It is a proof-of-concept for
  writing a complete application with Auth0 logins and registration, Stripe payment processing,
  and PostgREST as a persistent storage system.
---

<img alt="Budgetable Icon" src="https://budgetable.net/budgetable-icon.svg" class="figure center" />

## Purpose

Budgetable has a few key features that distinguish it from traditional assistive finance tools.
Its design accomplishes the following goals:

- It empowers people to organize their accounts and budgets
- It allows people to forecast their accounts' values based on thier budgets
- It does not store any financial information to remote servers or databases

## Design

The system has a moderately simple design, but still chooses to leverage a couple of external
services for tricky matters that require high security: [Auth0](https://auth0.com/) for credential
management, and [Stripe](https://stripe.com/) for payment processing.

It is built with the following systems as well:

- [PostgREST](https://postgrest.org/en/stable/) database integration
- [Haskell](https://www.haskell.org/) microservices
- [Yew](https://yew.rs/) WebAssembly front-end

The product is closed-source, however if you would like a tour of the infrastructure, please
[contact me](/contact.html) so we may schedule a meeting.
