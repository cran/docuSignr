% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/httr.R
\name{docu_envelope_status}
\alias{docu_envelope_status}
\title{Check status of envelope}
\usage{
docu_envelope_status(username = Sys.getenv("docuSign_username"),
  password = Sys.getenv("docuSign_password"),
  integrator_key = Sys.getenv("docuSign_integrator_key"), base_url,
  envelope_id)
}
\arguments{
\item{username}{docuSign username}

\item{password}{docuSign password}

\item{integrator_key}{docusign integratorKey}

\item{base_url}{base_url}

\item{envelope_id}{id of envelope}
}
\description{
Check status of envelope
}
\examples{
\dontrun{
login <- docu_login(demo = TRUE)
 envelopes <- docu_list_envelopes(base_url = login$baseUrl[1], from_date = "2017/1/1")
 envelope_id <- envelopes[envelopes$status == "completed","envelopeId"][1]
 status <- docu_envelope_status(base_url = login[1, 3], 
                           envelope_id = envelope_id)
}

}
