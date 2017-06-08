
[![Build Status](https://travis-ci.org/CannaData/docuSignr.svg?branch=master)](https://travis-ci.org/CannaData/docuSignr)[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/CannaData/docuSignR?branch=master&svg=true)](https://ci.appveyor.com/project/CannaData/docuSignR)

docuSignr
=========

[DocuSign](https://www.docusign.com/) is the leader in online document signing. They provide a REST API which allows for [embedded document](https://www.docusign.com/developer-center/recipes/signing-from-your-app) signing in several server-side languages, not currently including R.

The `docuSignr` package uses `httr` to embed DocuSign into Shiny applications.

Installation
============

`docuSignr` is available on CRAN and Github.

``` r
# from CRAN
install.packages("docuSignr")
# from Github
devtools::install_github("CannaData/docuSignr")
```

Requirements
============

For `docuSignr` to function you will need several things:

-   DocuSign account
-   DocuSign integrator key
-   DocuSign templates
-   DocuSign envelopes

Set-Up
======

It is recommended that you set the DocuSign username, password, and integrator key as environmental variables idealy in your .Rprofile.

``` r
Sys.setenv("docuSign_username" = "username")
Sys.setenv("docuSign_password" = "password")
Sys.setenv("docuSign_integrator_key" = "integrator_key")
```

Example
=======

``` r
library(docuSignr)
# login to get baseURL and accountID
login <- docu_login()
# load templates
templates <- docu_templates(base_url = login[1, "baseUrl"])
# create envelope
envelope <- docu_envelope(
  account_id = login[1, "accountId"],
  base_url = login[1, "baseUrl"],
  template_id = templates[1, "templateId"],
  template_roles = list(
    email = "example@example.com",
    name = "R-Test",
    roleName = "Patient",
    clientUserId = "1"
  ),
  email_subject = "R-Test",
  email_blurb = "R-Test"
)

# get URL
URL <- docu_embed(
  base_url = login[1, "baseUrl"],
  return_url = "https://www.google.com",
  envelope_id = envelope$envelopeId,
  # info here must be consistent with info in template_roles above
  signer_name = "R-Test",
  signer_email = "example@example.com",
  client_user_id = "1"
)

# sign document
browseURL(URL)
```

Code of Conduct
===============

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.

Also see [contributing](CONTRIBUTE.md).
