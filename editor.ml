open Eliom_parameter
open Eliom_content.Html5.D
open Eliom_service

open Storage
open Document
open Netencoding
open Patch

let () = Ocsigen_config.set_maxrequestbodysizeinmemory 1048576

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
  mutable pos: ((int * int) * (int * int));
  color: int
}

(* All connected clients by session id *)
let clients = Hashtbl.create 100

(* All session ids by document id *)
let docsesh = Hashtbl.create 100

(* Document mutexes *)
let doc_locks = Hashtbl.create 100

let create_session doc_id =
  let rec try_create count =
    if count = 0 then err "could not generate a session id"
    else
      let sid = String.init 16 (fun x -> Char.chr ((Random.int 26) + 65)) in
      if Hashtbl.mem clients sid then
        try_create (count - 1)
      else
        let session = {
          sid = sid;
          doc_id = doc_id;
          last_patch = 0;
          pos = ((0, 0), (0, 0));
          color = Random.int 360
        } in
        let () = Hashtbl.add clients sid session in
        let () =
          if Hashtbl.mem docsesh doc_id then
            Hashtbl.add (Hashtbl.find docsesh doc_id) sid ()
          else
            let sessions = Hashtbl.create 100 in
            Hashtbl.add sessions sid ();
            Hashtbl.add docsesh doc_id sessions
        in
        session
  in try_create 100

let destroy_session sid =
  let c = Hashtbl.find clients sid in
  Hashtbl.remove clients sid;
  if Hashtbl.mem docsesh c.doc_id then
    let sessions = Hashtbl.find docsesh c.doc_id in
    Hashtbl.remove sessions sid;
    if Hashtbl.length sessions = 0 then
      let () = Hashtbl.remove doc_locks c.doc_id in
      let () = Hashtbl.remove docsesh c.doc_id in
      ()
    else
      ()
  else
    ()

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

let patch_service_handler _ (sid, (value, newpos)) =
  let patch_in = patch_of_string (Url.decode ~plus:false value) in
  let s = Hashtbl.find clients sid in
  let sessions = Hashtbl.find docsesh s.doc_id in
  let cursorlist = Hashtbl.fold (fun cid () acc ->
    let c = Hashtbl.find clients cid in
    if sid <> cid then
      (`List [`Int c.color; `Int (fst (fst c.pos)); `Int (snd (fst c.pos));
      `Int (fst (snd c.pos)); `Int (snd (snd c.pos))])::acc
    else acc
  ) sessions [] in
  s.pos <- newpos;
  Lwt.return (Yojson.Basic.pretty_to_string (`Assoc [
      ("cursors", `List cursorlist);
      ("patch", `String (string_of_patch (accept_patch s.doc_id s patch_in)))
    ]))

let patch_service = 
   Eliom_registration.Html_text.register_post_service
    ~fallback: patch_no_post_service
    ~post_params:Eliom_parameter.
      (string "sid" ** (string "patch" **
      (* Cursor position *)
      ((int "csl" ** int "csc") ** (int "cel" ** int "cec"))))
   patch_service_handler

let create_doc_service =
  Eliom_registration.String_redirection.register_service
    ~options:`TemporaryRedirect
    ~path:["create_doc"]
    ~get_params:(string "title")
    (fun (title) () ->
       let title = Url.decode title in
       match document_create ctl with
       | None -> Lwt.return ""
       | Some newid -> 
          match set_document_metadata ctl newid {title} with
          | false -> err "Could not set document metadata"
          | true -> Lwt.return ("doc?id=" ^ newid))

let genuri ls = make_uri ~service:(static_dir ()) ls

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
              css_link ~uri:(genuri ["codemirror-5.8";"lib";"codemirror.css"]) ();
              js_script ~uri:(genuri ["codemirror-5.8";"lib";"codemirror.js"]) ();
              js_script ~uri:(genuri ["gui.js"]) ()])
            (body [h1 [pcdata ("Title: "^x.title)]])))

let close_service =
  Eliom_registration.Html_text.register_service
    ~path:["close"]
    ~get_params:(string "sid")
    (fun sid () -> destroy_session sid; Lwt.return "")

let main_service =
  Eliom_registration.Html5.register_service
    ~path:[]
    ~get_params:unit
    (fun () () ->
      Lwt.return Eliom_content.Html5.D.(
        html (head (title (pcdata "Collaborative Document Editor")) [] )
        (body [
          (h1 [pcdata ("Home")]);
          (h3 [pcdata ("Set a document title to make a new document.")]);
          (get_form create_doc_service (fun _ -> [
            raw_input ~input_type:`Text ~name:"title" ();
            raw_input ~input_type:`Submit ~value:"Create" ()
          ]))  
        ])
      )
    )
