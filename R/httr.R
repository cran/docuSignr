# Copyright (c) 2017 CannaData Solutions.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Lesser Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

#' Authenticate DocuSign
#'
#' Login to DocuSign and get baseURL and accountId
#'
#' @export
#' @import httr jsonlite
#' @importFrom magrittr %>%
#' @param username docuSign username
#' @param password docuSign password
#' @param integrator_key docusign integratorKey
#' @param demo indicate whether to use DocuSign demo server
#' @examples
#' \dontrun{
#' # assuming env variables are properly set up
#' (login <- docu_login())
#' }

docu_login <-
  function(username = Sys.getenv("docuSign_username"),
           password = Sys.getenv("docuSign_password"),
           integrator_key = Sys.getenv("docuSign_integrator_key"),
           demo = FALSE) {
    # XML for authentication
    auth <- docu_auth(username, password, integrator_key)
    
    url <- paste0('https://',
                  if (demo)
                    'demo'
                  else
                    'www',
                  '.docusign.net/restapi/v2/login_information')
    
    header <- docu_header(auth)
    
    # send login info
    # need back baseUrl and accountId info
    resp <- httr::GET(url, header)
    
    parsed <- parse_response(resp)
    
    parsed$loginAccounts
  }

#' Create document for particular instance to be signed
#'
#' Does envelope stuff
#'
#' @export
#' @inheritParams docu_login
#' @param account_id docuSign accountId
#' @param status envelope status
#' @param base_url docuSign baseURL
#' @param template_id docuSign templateId
#' @param template_roles list of parameters passed to template
#' @param email_subject docuSign emailSubject
#' @param email_blurb docuSign emailBlurb
#' @examples
#' \dontrun{
#' # assuming env variables are properly set up
#' login <- docu_login()
#' template <- docu_templates(base_url = login[1, "baseUrl"])
#' (env <- docu_envelope(username = Sys.getenv("docuSign_username"),
#'  password = Sys.getenv("docuSign_password"),
#'  integrator_key = Sys.getenv("docuSign_integrator_key"),
#'  account_id = login[1, "accountId"], base_url = login[1, "baseUrl"],
#'  template_id = template$templateId,
#'  template_roles = list(name = "Name", email = "email@example.com",
#'                       roleName = "Role", clientUserId = "1"),
#'  email_subject = "Subject", email_blurb = "Body"
#'  ))
#'  }

docu_envelope <-
  function(username = Sys.getenv("docuSign_username"),
           password = Sys.getenv("docuSign_password"),
           integrator_key = Sys.getenv("docuSign_integrator_key"),
           account_id,
           status = "sent",
           base_url,
           template_id,
           template_roles,
           email_subject,
           email_blurb) {
    # XML for authentication
    auth <- docu_auth(username, password, integrator_key)
    
    # request body
    if (!is.null(template_roles$clientUserId)) {
      body <-
        sprintf(
          '{"accountId": "%s",
          "status" : "%s",
          "emailSubject" : "%s",
          "emailBlurb": "%s",
          "templateId": "%s",
          "templateRoles": [{
          "email" : "%s",
          "name": "%s",
          "roleName": "%s",
          "clientUserId": "%s" }] }',
          account_id,
          status,
          email_subject,
          email_blurb,
          template_id,
          template_roles$email,
          template_roles$name,
          template_roles$roleName,
          template_roles$clientUserId
        )
  } else {
    body <-
      sprintf(
        '{"accountId": "%s",
        "status" : "%s",
        "emailSubject" : "%s",
        "emailBlurb": "%s",
        "templateId": "%s",
        "templateRoles": [{
        "email" : "%s",
        "name": "%s",
        "roleName": "%s" }] }',
        account_id,
        status,
        email_subject,
        email_blurb,
        template_id,
        template_roles$email,
        template_roles$name,
        template_roles$roleName
      )
    }
    
    url <- paste0(base_url, "/envelopes")
    
    header <- docu_header(auth)
    
    resp <- httr::POST(url, header, body = body)
    
    parsed <- parse_response(resp)
    
    parsed
    
    }

#' Embedded docuSign
#'
#' Get URL for embedded docuSign
#'
#' @export
#' @inheritParams docu_login
#' @param base_url docuSign baseURL
#' @param return_url URL to return to after signing
#' @param envelope_id ID for envelope returned from \code{docu_envelope}
#' @param signer_name Name of person signing document
#' @param signer_email Email of person signing document
#' @param client_user_id ID for signer
#' @param authentication_method Method application uses to authenticate user. Defaults to "None".
#' @examples
#' \dontrun{
#' # assuming env variables are properly set up
#' login <- docu_login()
#' template <- docu_templates(base_url = login[1, "baseUrl"])
#' env <- docu_envelope(username = Sys.getenv("docuSign_username"),
#'  password = Sys.getenv("docuSign_password"),
#'  integrator_key = Sys.getenv("docuSign_integrator_key"),
#'  account_id = login[1, "accountId"], base_url = login[1, "baseUrl"],
#'  template_id = template$templateId,
#'  template_roles = list(name = "Name", email = "email@example.com",
#'                       roleName = "Role", clientUserId = "1"),
#'  email_subject = "Subject", email_blurb = "Body"
#'  )
#' URL <- docu_embed(
#'  base_url = login[1, "baseUrl"], return_url = "www.google.com",
#'  signer_name = "Name", signer_email = "email@example.com",
#'  client_user_id = "1",
#'  envelope_id = env$envelopeId
#' )
#' }


docu_embedded_sign <-
  function(username = Sys.getenv("docuSign_username"),
           password = Sys.getenv("docuSign_password"),
           integrator_key = Sys.getenv("docuSign_integrator_key"),
           base_url,
           return_url,
           envelope_id,
           signer_name,
           signer_email,
           client_user_id,
           authentication_method = "None") {
    # XML for authentication
    auth <- docu_auth(username, password, integrator_key)
    
    # request body
    body <- list(
      authenticationMethod = authentication_method,
      email = signer_email,
      returnUrl = return_url,
      userName = signer_name,
      clientUserId = client_user_id
    )
    
    header <- docu_header(auth)
    
    url <-
      paste0(base_url, "/envelopes/", envelope_id, "/views/recipient")
    
    res <- httr::POST(url, header, body = body, encode = "json")
    
    parsed <- parse_response(res)
    
    parsed$url
    
  }

#' @rdname docu_embedded_sign
#' @inheritParams docu_embedded_sign
#' @param uri uri path
#' @export

docu_embedded_send <-
  function(username = Sys.getenv("docuSign_username"),
           password = Sys.getenv("docuSign_password"),
           integrator_key = Sys.getenv("docuSign_integrator_key"),
           base_url,
           return_url,
           uri,
           signer_name,
           signer_email,
           client_user_id,
           authentication_method = "None") {
    # XML for authentication
    auth <- docu_auth(username, password, integrator_key)
    
    # request body
    body <- list(
      authenticationMethod = authentication_method,
      email = signer_email,
      returnUrl = return_url,
      userName = signer_name,
      clientUserId = client_user_id
    )
    
    header <- docu_header(auth)
    
    url <- paste0(base_url, uri, "/views/sender")
    
    res <- httr::POST(url, header, body = body, encode = "json")
    
    parsed <- parse_response(res)
    
    parsed$url
    
  }

#' View templates
#'
#' See all templates associated with account
#'
#' @inheritParams docu_login
#' @param base_url docuSign baseURL
#' @export
#' @examples
#' \dontrun{
#' login <- docu_login()
#' templates <- docu_templates(base_url = login[1, 3])
#' }

docu_templates <-
  function(username = Sys.getenv("docuSign_username"),
           password = Sys.getenv("docuSign_password"),
           integrator_key = Sys.getenv("docuSign_integrator_key"),
           base_url) {
    # XML for authentication
    auth <- docu_auth(username, password, integrator_key)
    
    url <- paste0(base_url, "/templates")
    
    header <- docu_header(auth)
    
    res <- httr::GET(url, header)
    
    parsed <- parse_response(res)
    
    parsed$envelopeTemplates
    
  }

#' Download Document from DocuSign
#'
#' @export
#' @inheritParams docu_login
#' @param file a character string naming a file
#' @param base_url base_url
#' @param envelope_id id of envelope
#' @examples 
#' \dontrun{
#' login <- docu_login(demo = TRUE)
#'  envelopes <- docu_list_envelopes(base_url = login$baseUrl[1], from_date = "2017/1/1")
#'  envelope_id <- envelopes[envelopes$status == "completed","envelopeId"][1]
#'  file <- tempfile()
#'  document <- docu_download(file, base_url = login[1, 3], 
#'                            envelope_id = envelope_id)
#' }
#'

docu_download <-
  function(file,
           username = Sys.getenv("docuSign_username"),
           password = Sys.getenv("docuSign_password"),
           integrator_key = Sys.getenv("docuSign_integrator_key"),
           base_url,
           envelope_id) {
    # XML for authentication
    auth <- docu_auth(username, password, integrator_key)
    
    url <- paste0(base_url,
                  "/envelopes/",
                  envelope_id,
                  "/documents/combined")
    
    header <- docu_header(auth)
    
    document <- httr::GET(url, header)
    
    writeBin(httr::content(document, as = "raw"),
             con = file)
    
    file
    
  }

#' List envelopes since date
#' 
#' @export
#' @inheritParams docu_download
#' @param from_date character indicating begin date of search
#' @examples
#' \dontrun{
#' login <- docu_login(demo = TRUE)
#' envelopes <- docu_list_envelopes(base_url = login$baseUrl[1], from_date = "2017/1/1")
#' }
#' 

docu_list_envelopes <- function(username = Sys.getenv("docuSign_username"),
                                password = Sys.getenv("docuSign_password"),
                                integrator_key = Sys.getenv("docuSign_integrator_key"),
                                base_url,
                                from_date) {
  # XML for authentication
  auth <- docu_auth(username, password, integrator_key)
  
  url <- paste0(base_url, 
                "/envelopes/", 
                "status")
  
  header <- docu_header(auth)
  
  status <- httr::GET(url, header, query = list(from_date = from_date))
  
  parsed <- parse_response(status)
  
  parsed$envelopes
}

#' Check status of envelope
#'
#' @export
#' @inheritParams docu_download
#' @examples 
#' \dontrun{
#' login <- docu_login(demo = TRUE)
#'  envelopes <- docu_list_envelopes(base_url = login$baseUrl[1], from_date = "2017/1/1")
#'  envelope_id <- envelopes[envelopes$status == "completed","envelopeId"][1]
#'  status <- docu_envelope_status(base_url = login[1, 3], 
#'                            envelope_id = envelope_id)
#' }
#'

docu_envelope_status <-
  function(username = Sys.getenv("docuSign_username"),
           password = Sys.getenv("docuSign_password"),
           integrator_key = Sys.getenv("docuSign_integrator_key"),
           base_url,
           envelope_id) {
    # XML for authentication
    auth <- docu_auth(username, password, integrator_key)
    
    url <- paste0(base_url,
                  "/envelopes/",
                  envelope_id)
    
    header <- docu_header(auth)
    
    status <- httr::GET(url, header)
    
    parsed <- parse_response(status)
    
    parsed$status
  }

#' Process results from POST or GET
#'
#' @param response Result of POST or GET

parse_response <- function(response) {
  parsed <- response %>%
    httr::content(type = "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON()
  
  # parse errors
  if (http_error(response)) {
    stop(
      sprintf(
        "DocuSign API request failed [%s]\n%s\n<%s>",
        status_code(response),
        parsed$message,
        parsed$errorCode
      ),
      call. = FALSE
    )
  } else {
    return(parsed)
  }
}

#' Create XML authentication string
#'
#' @inheritParams docu_login

docu_auth <- function(username = Sys.getenv("docuSign_username"),
                      password = Sys.getenv("docuSign_password"),
                      integrator_key = Sys.getenv("docuSign_integrator_key")) {
  sprintf(
    "<DocuSignCredential>
    <Username>%s</Username>
    <Password>%s</Password>
    <IntegratorKey>%s</IntegratorKey>
    </DocuSignCredential>",
    username,
    password,
    integrator_key
  )
}

#' Create header for docuSign
#'
#' Create header for authentication with docuSign
#' @param auth XML object with authentication info

docu_header <- function(auth) {
  httr::add_headers('X-DocuSign-Authentication' = auth,
                    'Accept' = 'application/json')
}
