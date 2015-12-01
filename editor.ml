open Eliom_lib
open Eliom_content
open Eliom_parameter
open Storage
open Document
open Eliom_content.Html5.D
open Eliom_service

let ctl =
  match storage_open "127.0.0.1" 6379 with
  | Some x -> x
  | None -> failwith "Failed to connect to Redis"

let create_document getp postp =
  match document_create ctl with
  | Some newid -> Lwt.return newid
  | None -> Lwt.return ""

let main_service =
  Eliom_registration.Html5.register_service
    ~path:[]
    ~get_params:unit
    (fun () () ->
       Lwt.return
         Eliom_content.Html5.D.(html ( head (title (pcdata "Collaborative Document Editor"))
                     [js_script ~uri:(make_uri ~service:(static_dir ()) ["create_doc.js"]) ();]
               )
               (body [(h1 [pcdata ("Home")]);
                      (h3 [pcdata ("Welcome to the home page, where you can create you document.")]);
                      (h3 [pcdata ("Set a document name, and press \"Create\"")])])))

let create_doc_service =
  Eliom_registration.Html_text.register_service
    ~path:["create_doc"]
    ~get_params:(string "title")
    (fun (title) () ->
       match document_create ctl with
       | None -> Lwt.return "" (* TODO better way to handle *)
       | Some newid -> 
          match set_document_metadata ctl newid {title} with
          | false -> failwith "Could not set document metadata"
          | true -> Lwt.return newid)

let access_doc_service = 
  Eliom_registration.Html5.register_service
    ~path:["doc"]
    ~get_params:(string "id")
    (fun (id) () ->
      match get_document_metadata ctl id with
      | None ->      
         Lwt.return Eliom_content.Html5.D.(html (head (title (pcdata "Unknown Document")) []) 
                                                (body [h1 [pcdata ("Document "^id^" does not exist.")]]))
      | Some x ->
         Lwt.return Eliom_content.Html5.D.(html ( head (title (pcdata "Unknown Document"))
                                                       [css_link ~uri:(make_uri ~service:(static_dir ()) ["codemirror-5.8";"lib";"codemirror.css"]) ();
                                                        js_script ~uri:(make_uri ~service:(static_dir ()) ["codemirror-5.8";"lib";"codemirror.js"]) ();
                                                        js_script ~uri:(make_uri ~service:(static_dir ()) ["gui.js"]) ()]
                                                )
                                                (body [h1 [pcdata ("Title: "^x.title)]])))


(* let doc_create_form = Eliom_registration.Html5.register_service ["doc_create_form"] unit *)
(*   (fun () () -> *)
(*      let f =  *)
(*        (Html5.D.post_form  *)
  

(* let gen_home _ () = *)
(*   Lwt.return Eliom_content.Html5.D.(html ( head (title (pcdata "Collaborative Document Editor")) *)
(*                                                 [js_link ~uri:(make_uri ~service:(static_dir ()) ["create_doc.js"]) ();] *)
(*                                          ) *)
(*                                          (body [(h1 [pcdata ("Home")]); *)
(*                                                 (h3 [pcdata ("Welcome to the home page, where you can create you document.")]); *)
(*                                                 (h3 [pcdata ("Set a document name, and press \"Create Document\"")])])) *)

(* let main_service =  *)
(*   Eliom_registration.Html5.register_service  *)
(*     ~path:[] *)
(*     ~get_params:[] *)
(*     gen_home *)

(* let main_service = *)
(*   Eliom_registration.Html_text.register_service *)
(*     ~path:["create"] *)
(*     ~get_params:Eliom_parameter.any *)
(*     create_document *)


(* IMP*)
(* let writeid id () = *)
(*   Lwt.return *)
(*     Html5.D.(html *)
(*                (head (title (pcdata "Hello")) []) *)
(*                (body [p [pcdata "id was: "; *)
(*                          strong [pcdata id];]])) *)

(* IMP *)
(* let idoc_service = *)
(*   Eliom_registration.Html5.register_service *)
(*     ~path:["doc"] *)
(*     ~get_params:(string "id") *)
(*     writeid *)

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
