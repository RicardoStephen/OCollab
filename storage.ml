(*
 * Storage Module Implementation
 *)

open Patch
open Document
open Redis

type controller = {
    addr: string;
    port: int;
    conn: Redis_sync.Client.connection
  }

let storage_open addr port =
  let open Redis_sync.Client in
  try
    let c = connect { host = addr; port = port } in
    Some { addr = addr; port = port; conn = c }
  with _ -> None

let storage_close ctl =
  let open Redis_sync.Client in
  let conn = ctl.conn in
  quit conn

let document_create ctl =
  let open Redis_sync.Client in
  let conn = ctl.conn in
  let rec try_create count =
    if count = 0 then
      (* Tried too many times, just give up *)
      None
    else
      (* Generate a random id - 8 characters, A - Z *)
      let id = String.init 8 (fun x -> Char.chr ((Random.int 26) + 65)) in
      let key = ("document:" ^ id) in
      if exists conn key then
        try_create (count - 1)
      else
        (set conn key id; Some id)
  in
  (* Try 100 times to create a new document *)
  try_create 100

let get_document_list ctl =
  failwith "TODO later"

let get_document_metadata ctl id =
  let open Redis_sync.Client in
  let conn = ctl.conn in
  if exists conn ("document:" ^ id ^ "metadata") then
    failwith "TODO now"
  else
    None

let get_document_patches ctl id =
  failwith "TODO later"

let get_document_text ctl id =
  failwith "TODO later"

let get_document ctl id =
  let open Redis_sync.Client in
  let conn = ctl.conn in
  if exists conn ("document:" ^ id) then
    failwith "TODO now"
  else
    None

let set_document_metadata ctl id data =
  let open Redis_sync.Client in
  let conn = ctl.conn in
  if exists conn ("document:" ^ id) then
    let key = "document:" ^ id ^ ":metadata" in
    hset conn key "title" data.title
  else
    false

let add_document_patches ctl id patches =
  let open Redis_sync.Client in
  let conn = ctl.conn in
  if exists conn ("document:" ^ id) then
    let key = "document:" ^ id ^ ":patches" in
    List.fold_left (fun r p ->
      r && (rpush conn key (string_of_patch p)) > 0) true patches
  else
    false

let set_document_patches ctl id patches =
  let open Redis_sync.Client in
  let conn = ctl.conn in
  if exists conn ("document:" ^ id) then
    let key = "document:" ^ id ^ ":patches" in
    (del conn [key] == 1) &&
    (add_document_patches ctl id patches)
  else
    false

let set_document_text ctl id text =
  let open Redis_sync.Client in
  let conn = ctl.conn in
  if exists conn ("document:" ^ id) then
    let key = "document:" ^ id ^ ":text" in
    (set conn key text; true)
  else
    false

let set_document ctl id doc =
  let open Redis_sync.Client in
  let conn = ctl.conn in
  if exists conn ("document:" ^ id) then
    let key = "document:" ^ doc.id in
    set conn key doc.id;
    (set_document_metadata ctl doc.id doc.metadata) &&
    (set_document_patches ctl doc.id doc.patches) &&
    (set_document_text ctl doc.id doc.text)
  else
    false
