

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

(* Using Yojson for this *)
let rec string_of_patch p = (* failwith "unimplemented" *)
  (*let f = fun acc x ->
            let op_str = match x.op with Insert -> "Insert," | Delete -> "Delete," in
            op_str ^ string_of_int x.pos ^ "," ^ x.text ^ ";" ^ acc in
  List.fold_left f "" p
*)
  let rec get_json p j =
    (* Convert patch to Yojson representing edits *)
    match p with
    | h::t ->
      let to_add =
        if h.op = Insert then
          (* [Yojson.Basic.from_string "{\"op\":\"Insert\",\"pos\":0,\"text\":asdfasfasfasdf}"] *)
          Yojson.Basic.from_string ("{\"op\":\"Insert\",\"pos\":" ^ (string_of_int h.pos) ^ ",\"text\":\"" ^ h.text ^  "\"}")
        else
          (* [Yojson.Basic.from_string "{\"op\":\"Delete\",\"pos\":0,\"text\":asdfasfasfasdf}"] *)
          Yojson.Basic.from_string ("{\"op\":\"Delete\",\"pos\":" ^ (string_of_int h.pos) ^ ",\"text\":\"" ^ h.text ^  "\"}")
      in
      (get_json t (to_add::j))  (*Does this result in correct order?*)
    | [] -> (* j *) `List(j) (*Creating json list from list of json elements where each element corresponds to one edit*)

  Yojson.Basic.to_string (get_json p [])

let patch_of_string p = failwith "unimplemented"



  (* Yojson.Basic.to_string "{\"a\":1}" *)
  (* Yojson.Bsaic.from_string *)