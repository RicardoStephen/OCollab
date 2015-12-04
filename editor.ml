open Eliom_lib
open Eliom_content
open Eliom_parameter
open Storage
open Document
open Eliom_content.Html5.D
open Eliom_service
open Netencoding
open Patch

(* TODO better handle error cases *)

let err s = print_string (s ^ "\n"); failwith s

let ctl =
  match storage_open "127.0.0.1" 6379 with
  | Some x -> x
  | None -> err "Failed to connect to Redis"

let create_document getp postp =
  match document_create ctl with
  | Some newid -> Lwt.return newid
  | None -> Lwt.return ""

let last_patch =
  Eliom_reference.Volatile.eref ~scope:Eliom_common.default_session_scope (-1)

let doc_id =
  Eliom_reference.Volatile.eref
    ~scope:Eliom_common.default_session_scope
    ""

let doc_locks = Hashtbl.create 100

let accept_patch id p =
  Mutex.lock (Hashtbl.find doc_locks id);
  let n = Eliom_reference.Volatile.get last_patch in
  let ps = (
    match get_document_patches ctl id n with
    | None -> err "unable to read document patches"
    | Some ps -> ps)
  in
  let q = List.fold_left Patch.compose Patch.empty_patch ps in
  let (q', p') = Patch.merge p q in
  let result = add_document_patches ctl id [p'] in
  Mutex.unlock (Hashtbl.find doc_locks id);
  match result with
  | false -> err "unable to add patch to document"
  | true  ->
    match get_document_patch_count ctl id with
    | None -> err "unable to read document patch count"
    | Some last -> Eliom_reference.Volatile.set last_patch last; q'

let main_service =
  Eliom_registration.Html5.register_service
    ~path:[]
    ~get_params:unit
    (fun () () -> Lwt.return Eliom_content.Html5.D.(
      html
      (head
        (title (pcdata "Collaborative Document Editor"))
        [js_script ~uri:(make_uri ~service:(static_dir ()) ["create_doc.js"]) ()])
      (body
        [(h1 [pcdata ("Home")]);
        (h3 [pcdata ("Welcome to the home page, where you can create you document.")]);
        (h3 [pcdata ("Set a document name, and press \"Create\"")])])))

let patch_no_post_service =
  Eliom_registration.Html_text.register_service
    ~path:["exchange"]
    ~get_params:Eliom_parameter.unit
    (fun () () -> raise Eliom_common.Eliom_404)

let patch_service_handler _ value =
  let patch_in = patch_of_string (Url.decode value) in
  let id = Eliom_reference.Volatile.get doc_id in
  Lwt.return (string_of_patch (accept_patch id patch_in))

let patch_service = 
   Eliom_registration.Html_text.register_post_service
    ~fallback: patch_no_post_service
    ~post_params:Eliom_parameter.(string "patch")
   patch_service_handler

let create_doc_service =
  Eliom_registration.Html_text.register_service
    ~path:["create_doc"]
    ~get_params:(string "title")
    (fun (title) () ->
       let title = Url.decode title in
       match document_create ctl with
       | None -> Lwt.return "" (* TODO better way to handle *)
       | Some newid -> 
          match set_document_metadata ctl newid {title} with
          | false -> err "Could not set document metadata"
          | true -> Lwt.return newid)

let access_doc_service = 
  Eliom_registration.Html5.register_service
    ~path:["doc"]
    ~get_params:(string "id")
    (fun (id) () ->
      Eliom_reference.Volatile.set doc_id id;
      if not (Hashtbl.mem doc_locks id) then
        Hashtbl.replace doc_locks id (Mutex.create ())
      else ();
      match get_document_patch_count ctl id with
      | None -> err ("couldn't read document patch count for " ^ id)
      | Some n -> Eliom_reference.Volatile.set last_patch n;
      match get_document_metadata ctl id with
      | None -> Lwt.return Eliom_content.Html5.D.(
        html
          (head (title (pcdata "Unknown Document")) []) 
          (body [h1 [pcdata ("Document "^id^" does not exist.")]]))
      | Some x ->
        let text = (
          match get_document_text ctl id with
          | None -> ""
          | Some s -> s)
        in
        let script = Printf.sprintf
          "var doc_id = \'%s\';\n\
           var doc_text = %s;\n\
           var doc_title = \'%s\'\n\
           console.log([doc_id, doc_text, doc_title]);\n"
          id (Yojson.to_string (`String text)) x.title
        in
        let script_node = Eliom_content.Html5.F.script (cdata_script script) in
        Lwt.return Eliom_content.Html5.D.(
          html
            (head
              (title (pcdata "Unknown Document"))
              [script_node;
              css_link ~uri:(make_uri ~service:(static_dir ()) ["codemirror-5.8";"lib";"codemirror.css"]) ();
              js_script ~uri:(make_uri ~service:(static_dir ()) ["codemirror-5.8";"lib";"codemirror.js"]) ();
              js_script ~uri:(make_uri ~service:(static_dir ()) ["gui.js"]) ()])
            (body [h1 [pcdata ("Title: "^x.title)]])))

let get_full_doc_service =
  Eliom_registration.Html_text.register_service
    ~path:["get_doc_text"]
    ~get_params:(string "id")
    (fun (id) () ->
      match get_document_text ctl id with
      | None -> Lwt.return "Empty Document"
      | Some x -> Lwt.return x)
