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



open Async.Std
open Patch

(* Serialized to a format to use for HTTP requests *)
type serialized

type library

(* composed of doc_id, patch *)
type request

(* composed of doc_id, patch, document text*)
type response

val serialize : patch -> serialized

val deserialize : serialized -> patch

val parse_document_id: request -> doc_id

val parse_serialized: request -> serialized

val gen_request:

(* modify the current document *)
(* Handles multiple documents *)
val modify

(* Handle new document requests *)
(* *)





module My_app =
  Eliom_registration.App (struct
                           let application_name = "graffiti"
                         end)

let main_service =
  My_app.register_service
    ~path:[""]
    ~get_params:Eliom_parameter.unit
    (fun () () ->
     Lwt.return
       (html
          (head (title (pcdata "Graffiti")) [])
          (body [h1 [pcdata "Graffiti"]]) ) )
