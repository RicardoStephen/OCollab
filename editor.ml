open Eliom_lib
open Eliom_content
open Eliom_parameter
open Patch
open Document
open Storage
open Eliom_content.Html5.D

let ctl =
  match storage_open "127.0.0.1" 6379 with
  | Some x -> x
  | None -> failwith "Failed to connect to Redis"

let clients = Hashtbl.create 20

type session_id = string

type client_info = {
  (* Session id of the client - this is the hashtable key *)
  sid : session_id;
  (* Document id that the client is editing *)
  docid : document_id;
  (* Current patch that the client is on *)
  patch_index : int;
  (* Current queue of patches to be sent to the client *)
  patch_queue : patch list
}

let create_document getp postp =
  match document_create ctl with
  | Some newid -> Lwt.return newid
  | None -> Lwt.return ""

let create_service =
  Eliom_registration.Html_text.register_service
    ~path:["create"]
    ~get_params:Eliom_parameter.any
    create_document

let create_session getp postp =
  let sid = String.init 16 (fun x -> Char.chr ((Random.int 26) + 65)) in
  Lwt.return sid

let session_service_fallback =
  Eliom_registration.Html_text.register_service
    ~path:["session"]
    ~get_params:Eliom_parameter.any
    (fun _ _ -> Lwt.return "ERROR")

let session_service =
  Eliom_registration.Html_text.register_post_service
    ~fallback:session_service_fallback
    ~post_params:Eliom_parameter.any

