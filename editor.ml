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
  patch_index : int;
  (* Current queue of patches to be sent to the client
   * Represented as a stack for easy conversion into a list *)
  patch_queue : patch Stack.t
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
          patch_index = 0;
          patch_queue = Stack.create ()
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
      let npatch = patch_of_json (Util.member "patch" djson) in
      
      (* TODO Compose patches properly *)
      let pjson =
        let rec list_of_stack acc =
          if Stack.is_empty ci.patch_queue then
            acc
          else
            list_of_stack (
              (`String (string_of_patch (Stack.pop ci.patch_queue)))
              :: acc)
        in
        `List (list_of_stack [])
      in
      (* TODO Add patch to document storage *)
      (* Broadcast new patch to all clients *)
      Hashtbl.iter (fun sid info ->
        if ci.docid = info.docid && ci.sid <> info.sid then
          Stack.push npatch info.patch_queue
        else
          ()
      ) clients;
      (* Return data to client *)
      Lwt.return (pretty_to_string (`Assoc [("patches", pjson)]))
    with
      _ -> error_handler () ()
  else
    error_handler () ()

let data_service =
  register_service "data" (string "sid" ** string "data") get_data
