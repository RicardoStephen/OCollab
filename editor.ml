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

type client_info = {
  sid : string;
  doc_id : string;
  mutable last_patch : int;
}

let clients = Hashtbl.create 100
let create_session doc_id =
  let rec try_create count =
    if count = 0 then err "could not generate a session id"
    else
      let sid = String.init 16 (fun x -> Char.chr ((Random.int 26) + 65)) in
      if Hashtbl.mem clients sid then
        try_create (count - 1)
      else
        let session =  {sid = sid; doc_id = doc_id; last_patch = 0} in
        Hashtbl.add clients sid session;
        session
  in try_create 100

let doc_locks = Hashtbl.create 100

let accept_patch id session p =
  Mutex.lock (Hashtbl.find doc_locks id);
  let ps = (
    match get_document_patches ctl id session.last_patch with
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
    | Some last -> session.last_patch <- last; q'

let patch_no_post_service =
  Eliom_registration.Html_text.register_service
    ~path:["exchange"]
    ~get_params:Eliom_parameter.unit
    (fun () () -> raise Eliom_common.Eliom_404)

let patch_service_handler _ (sid, value) =
  let patch_in = patch_of_string (Url.decode ~plus:false value) in
  let s = Hashtbl.find clients sid in
  Lwt.return (string_of_patch (accept_patch s.doc_id s patch_in))

let patch_service = 
   Eliom_registration.Html_text.register_post_service
    ~fallback: patch_no_post_service
    ~post_params:
      (Eliom_parameter.(string "sid") ** Eliom_parameter.(string "patch"))
   patch_service_handler

let create_doc_service =
  Eliom_registration.String_redirection.register_service
    ~options:`TemporaryRedirect
    ~path:["create_doc"]
    ~get_params:(string "title")
    (fun (title) () ->
       let title = Url.decode title in
       match document_create ctl with
       | None -> Lwt.return "" (* TODO better way to handle *)
       | Some newid -> 
          match set_document_metadata ctl newid {title} with
          | false -> err "Could not set document metadata"
          | true -> Lwt.return ("doc?id=" ^ newid))

let access_doc_service = 
  Eliom_registration.Html5.register_service
    ~path:["doc"]
    ~get_params:(string "id")
    (fun (id) () ->
      let session = create_session id in
      if not (Hashtbl.mem doc_locks id) then
        Hashtbl.replace doc_locks id (Mutex.create ())
      else ();
      match get_document_patch_count ctl id with
      | None -> err ("couldn't read document patch count for " ^ id)
      | Some n -> session.last_patch <- n;
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
           var sid = \'%s\';\n"
          id (Yojson.to_string (`String text)) x.title session.sid
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

let main_service =
  Eliom_registration.Html5.register_service
    ~path:[]
    ~get_params:unit
    (fun () () ->
      Lwt.return Eliom_content.Html5.D.(
        html (head (title (pcdata "Collaborative Document Editor")) [] )
        (body [
          (h1 [pcdata ("Home")]);
          (h3 [pcdata ("Welcome to the home page, where you can create you document.")]);
          (h3 [pcdata ("Set a document name, and press \"Create\"")]);
          (get_form create_doc_service (fun _ -> [
            raw_input ~input_type:`Text ~name:"title" ();
            raw_input ~input_type:`Submit ~value:"Create" ()
          ]))  
        ])
      )
    )
