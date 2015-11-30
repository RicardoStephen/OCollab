open Eliom_lib
open Eliom_content
open Eliom_parameter
open Storage
open Eliom_content.Html5.D

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

let writeid id () =
  Lwt.return 
    Html5.D.(html
               (head (title (pcdata "Hello")) [])
               (body [p [pcdata "id was: ";
                         strong [pcdata id];]])) 

let idoc_service =
  Eliom_registration.Html5.register_service
    ~path:["doc"]
    ~get_params:(string "id")
    writeid

(*let init_doc_access_service =
  Eliom_registration.Html_text.register_service
    ~path:["doc"]
    ~get_params:(string "id")
    (fun (id) () ->
     Lwt.return Eliom_content.Html5.D.(
       html
         (head (title (pcdata "")) [])
         (body
            [p [pcdata "The current Document is"]]))) *)
