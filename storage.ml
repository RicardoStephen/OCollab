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
    quit ctl

let document_create ctl =
  let open Redis_sync.Client in
    let try_create count =
      if count = 0 then
        (* Tried too many times, just give up *)
        None
      else
        (* Generate a random id - 8 characters, A - Z *)
        let id = String.init 8 (fun x -> Char.chr ((Random.int 26) + 65)) in
        let key = ("document:" ^ id) in
        if exists ctl key then
          try_create (count - 1)
        else
          if hset ctl key "id" id then
            id
          else
            None
    in
    (* Try 100 times to create a new document *)
    try_create 100

let get_document_list ctl =
  failwith "TODO later"

let get_document ctl id =
  let open Redis_sync.Client in
    if exists ctl ("document:" ^ id) then
      failwith "TODO now"
    else
      None

let get_document_metadata ctl id =
  failwith "TODO later"

let get_document_patches ctl id =
  failwith "TODO later"

let set_document ctl id doc =
  let open Redis_sync.Client in
  let key = "document:" ^ doc.id in
  (hset ctl key "id" doc.id) &&
  (hset ctl key "metadata" "TODO now") &&
  (hset ctl key "patches" "TODO now") &&
  (hset ctl key "text" "TODO now")

let set_document_metadata ctl id data =
  let open Redis_sync.Client in
  let key = "document:" ^ doc.id in
  (hset ctl key "metadata" "TODO now")

let add_document_patches ctl id patches =
  let open Redis_sync.Client in
  let key = "document:" ^ doc.id in
  (hset ctl key "patches" "TODO now")

(* TODO now, add text additions *)
