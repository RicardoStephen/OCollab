open Patch
open Document

(* represents the position of a user's cursor on the document *)
type selection

(* composed of doc_id, patch list, selection *)
type request

(* composed of doc_id, patch list, document text, selection list*)
type response

(* Parse request *)
val parse_req_id: request -> doc_id

val parse_req_patches: request -> patch list

val parse_req_selection: request -> selection

(* Parse response *)
val parse_resp_id: response -> doc_id

val parse_resp_patches: response -> patch list

val parse_resp_text: response -> document_text

val parse_resp_selections: response -> selection list
