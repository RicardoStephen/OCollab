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

type session_id = string

type client_info = {
  (* Session id of the client - this is the hashtable key *)
  sid : session_id;
  (* Document id that the client is editing *)
  docid : document_id;
  (* Current patch that the client is on *)
  mutable patch_index : int
}

let clients = Hashtbl.create 20

let error_handler _ _ =
  raise Eliom_common.Eliom_404

let anyp = Eliom_parameter.any

let decodeURIComponent = Netencoding.Url.decode

let register_service path params handler =
  let fallback = Eliom_registration.Html_text.register_service
    ~path:[path]
    ~get_params:Eliom_parameter.any
    error_handler in
  let service = Eliom_registration.Html_text.register_post_service
    ~fallback:fallback
    ~post_params:params
    handler in
  service

let create_document getp (title) =
  match document_create ctl with
  | Some newid ->
    ignore (set_document_metadata ctl newid
      { title = decodeURIComponent title });
    Lwt.return newid
  | None -> Lwt.return ""

let create_service =
  register_service "create" (string "title") create_document

let create_session getp (docid) =
  let rec try_create count =
    if count = 0 then
      error_handler () ()
    else
      let sid = String.init 16 (fun x -> Char.chr ((Random.int 26) + 65)) in
      if Hashtbl.mem clients sid then
        try_create (count - 1)
      else
        let ci = {
          sid = sid;
          docid = docid;
          patch_index = 0
        } in
        Hashtbl.add clients sid ci;
        Lwt.return sid
  in
  try_create 100

let session_service =
  register_service "session" (string "docid") create_session

let get_init getp (sid) =
  if Hashtbl.mem clients sid then
    let ci = Hashtbl.find clients sid in
    (* Get entire document text up to this point *)
    let title =
      match get_document_metadata ctl ci.docid with
      | Some x -> x.title
      | None -> ""
    in
    let text =
      match get_document_text ctl ci.docid with
      | Some x -> x
      | None -> ""
    in
    let count =
      match get_document_patch_count ctl ci.docid with
      | Some x -> x
      | None -> 0
    in
    ci.patch_index <- count;
    Lwt.return (Yojson.Basic.pretty_to_string
      (`Assoc [("title", `String title); ("text", `String text)]))
  else
    error_handler () ()

let init_service =
  register_service "init" (string "sid") get_init

let get_data getp (sid, data) =
  if Hashtbl.mem clients sid then
    try
      let open Yojson.Basic in
      let ci = Hashtbl.find clients sid in
      (* Parse data as json *)
      let djson = from_string (decodeURIComponent data) in
      let newpatch = patch_of_json (Util.member "patch" djson) in
      
      (* Get new patches *)
      let plist =
        match get_document_patches ctl ci.docid ci.patch_index with
        | Some x -> x
        | None -> []
      in
      (* Compose all patches together *)
      let compatch = List.fold_left compose [] plist in
      let retpatch, addpatch = merge newpatch compatch in
      let _ = add_document_patches ctl ci.docid [addpatch] in
      let patchcount =
        match get_document_patch_count ctl ci.docid with
        | Some x -> x
        | None -> ci.patch_index
      in
      ci.patch_index <- patchcount;
      (* Return data to client *)
      Lwt.return (pretty_to_string
        (`Assoc [("patch", json_of_patch retpatch)]))
    with
      _ -> error_handler () ()
  else
    error_handler () ()

let data_service =
  register_service "data" (string "sid" ** string "data") get_data
