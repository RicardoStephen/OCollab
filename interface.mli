open Patch

type selection

(* composed of doc_id, patch, selection *)
type request

(* composed of doc_id, patch, document text, selection list*)
type response

val parse_req_id: request -> doc_id

val parse_req_patch: request -> patch

val parse_resp_id: response -> doc_id

val parse_resp_patch: response -> patch

val parse_resp_text: response -> document_text
