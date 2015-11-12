(* Reference: https://ocsigen.org/tuto/manual/application
              http://ocsigen.org/eliom/4.2/manual/server-services *)

(* Register application *)
(* main service should send gui js *)
(* addtitional services *)
(* - Send codemirror code *)
(* - handle edit actions *)
(* - handle update requests *)
(* - handles initial document fetch. Should instantiate a new document if it does not
     exist *)

(* TODO This is what an elium applicaiton or service looks like (see below). Does it have
   any place in a mli? Maybe this all should be part of the server.ml file, but inteface
   allows the server to parse json from gui, do server-side manipulations on pathches,
   and interface with the storage system? *)

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
