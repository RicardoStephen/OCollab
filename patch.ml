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

let slice s a b =
  let a = max a 0 in
  let b = min (String.length s) b in
  if b <= a then "" else String.sub s a (b - a)

let merge p1 p2 =
  let flip (a, b) = (b, a) in
  let nonempty edit = if String.length edit.text = 0 then [] else [edit] in
  let rec merge_edit e1 e2 =
    let len1 = String.length e1.text in
    let len2 = String.length e2.text in
    let end1 = e1.pos + len1 in
    let end2 = e2.pos + len2 in
    if e1.pos > e2.pos || (e1.pos = e2.pos && end1 > end2) then
      flip (merge_edit e2 e1)
    else
      match (e1.op, e2.op) with
      | (Insert, Delete) ->
        ([{e2 with pos = e2.pos + (String.length e1.text)}], [e1])
      | (Insert, Insert) ->
        ([{e2 with pos = e2.pos + (String.length e1.text)}], [e1])
      | (Delete, Delete) ->
        let a = min end1 end2 in
        let b = max e1.pos e2.pos in
        if b > a then
          ([{e2 with pos = e2.pos - len1}], [e1])
        else
          (nonempty {e2 with pos = e1.pos; text = slice e2.text (a - e2.pos) len2},
          compose
            (nonempty {e1 with text = slice e1.text 0 (b - e1.pos)})
            (nonempty {e1 with text = slice e1.text (a - e1.pos) len1}))
      | (Delete, Insert) ->
        if end1 <= e2.pos then
          ([{e2 with pos = e2.pos - len1}], [e1])
        else
          ([{e2 with pos = e1.pos}],
          compose
            (nonempty {e1 with text = slice e1.text 0 (e2.pos - e1.pos)})
            (nonempty {
              e1 with pos = e1.pos + len2;
              text = slice e1.text (e2.pos - e1.pos) len1}))
  in
  let rec go p1 p2 =
    match (p1, p2) with
    | ([], _) -> (p2, p1)
    | (_, []) -> (p2, p1)
    | (a::[], b::[]) -> merge_edit a b
    | (a::[], b::t) ->
      let (b', a')  = merge_edit a b in
      let (t', a'') = go a' t in
      (compose b' t', a'')
    | (a::t, b) ->
      let (b', a')  = go [a] b in
      let (b'', t') = go t b' in
      (b'', compose a' t')
  in
  go p1 p2

(* This might end up being slow. Two ways of making it faster would be to use a
 * rope instead of a string, or to require patches to be sorted by edit
 * position. *)
let apply_patch doc p =
  let apply_edit doc e =
    let len = String.length doc in
    let before = String.sub doc 0 e.pos in
    match e.op with
    | Insert -> before ^ e.text ^ (slice doc e.pos len)
    | Delete -> before ^ (slice doc (e.pos + String.length e.text) len)
  in
  List.fold_left apply_edit doc p

(* Using Yojson for serialization *)

let json_of_patch p =
  `List (List.map (fun e ->
    let op = match e.op with Insert -> "Insert" | Delete -> "Delete" in
    let pos = e.pos in
    let text = e.text in
    `Assoc [("op", `String op); ("pos", `Int pos); ("text", `String text)]
  ) p)

let string_of_patch p =
  Yojson.Basic.pretty_to_string (json_of_patch p)

let patch_of_json json =
  let open Yojson.Basic.Util in
  try
    List.map
      (fun ej -> {
        op = (match to_string (member "op" ej) with
          | "Insert" -> Insert
          | "Delete" -> Delete
          | _ -> failwith "Invalid operation");
        pos = to_int (member "pos" ej);
        text = to_string (member "text" ej)
      })
      (to_list json)
  with
    _ -> failwith "Invalid patch json string"

let patch_of_string s =
  patch_of_json (Yojson.Basic.from_string s)
