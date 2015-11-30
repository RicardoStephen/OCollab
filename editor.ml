open Eliom_lib
open Eliom_content
open Storage

let ctl =
  match storage_open "127.0.0.1" 6379 with
  | Some x -> x
  | None -> failwith "Failed to connect to Redis"

let create_document getp postp =
  match document_create ctl with
  | Some newid -> Lwt.return newid
  | None -> Lwt.return ""

let main_service =
  Eliom_registration.Html_text.register_service
    ~path:["create"]
    ~get_params:Eliom_parameter.any
    create_document
