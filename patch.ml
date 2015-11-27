type operation = Insert | Delete

type edit = {op : operation; pos : int; text : string}

type patch = edit list

type document_text = string

(* Implementation *)

let empty_patch = []

let empty_doc = ""

let compose p1 p2 = p1 @ p2

let add_edit ed p = compose p [ed]

let inverse p =
  let inverse_op op =
    match op with
    | Insert -> Delete
    | Delete -> Insert
  in
  let inverse_edit edit =
    {op = inverse_op edit.op; pos = edit.pos; text = edit.text}
  in
  let rec helper p =
    match p with
    | [] -> []
    | h::t -> compose (helper t) [inverse_edit h]
  in
  helper p

let merge p1 p2 = failwith "unimplemented"

let apply_patch doc patch = failwith "unimplemented"

let string_of_patch p = failwith "unimplemented"

let patch_of_string p = failwith "unimplemented"
